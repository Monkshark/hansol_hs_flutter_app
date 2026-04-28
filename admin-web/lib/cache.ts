'use client';
import { useEffect, useRef, useState, useCallback } from 'react';

interface CacheEntry<T> {
  data: T;
  timestamp: number;
}

const memoryCache = new Map<string, CacheEntry<any>>();
const inFlight = new Map<string, Promise<any>>();

const DEFAULT_TTL_MS = 60_000;

export function getCached<T>(key: string): T | undefined {
  return memoryCache.get(key)?.data as T | undefined;
}

export function setCached<T>(key: string, data: T) {
  memoryCache.set(key, { data, timestamp: Date.now() });
}

export function invalidateCache(prefix?: string) {
  if (!prefix) {
    memoryCache.clear();
    return;
  }
  for (const k of Array.from(memoryCache.keys())) {
    if (k.startsWith(prefix)) memoryCache.delete(k);
  }
}

interface UseCachedOptions {
  ttlMs?: number;
  enabled?: boolean;
}

export function useCached<T>(
  key: string | null,
  fetcher: () => Promise<T>,
  options: UseCachedOptions = {}
): {
  data: T | undefined;
  loading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
  setData: (updater: (prev: T | undefined) => T) => void;
} {
  const { ttlMs = DEFAULT_TTL_MS, enabled = true } = options;
  const cached = key ? memoryCache.get(key) : undefined;
  const [data, setData] = useState<T | undefined>(cached?.data);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;

  const fetch = useCallback(async (force = false) => {
    if (!key) return;
    const entry = memoryCache.get(key);
    if (!force && entry && Date.now() - entry.timestamp < ttlMs) {
      setData(entry.data);
      return;
    }
    if (inFlight.has(key)) {
      try {
        const result = await inFlight.get(key);
        setData(result);
      } catch (e) {
        setError(e as Error);
      }
      return;
    }
    if (!entry) setLoading(true);
    const promise = fetcherRef.current()
      .then(result => {
        memoryCache.set(key, { data: result, timestamp: Date.now() });
        setData(result);
        setError(null);
        return result;
      })
      .catch(e => {
        setError(e as Error);
        throw e;
      })
      .finally(() => {
        setLoading(false);
        inFlight.delete(key);
      });
    inFlight.set(key, promise);
    try { await promise; } catch {}
  }, [key, ttlMs]);

  useEffect(() => {
    if (!enabled || !key) return;
    fetch();
  }, [key, enabled, fetch]);

  const updateData = useCallback((updater: (prev: T | undefined) => T) => {
    setData(prev => {
      const next = updater(prev);
      if (key) memoryCache.set(key, { data: next, timestamp: Date.now() });
      return next;
    });
  }, [key]);

  return {
    data,
    loading,
    error,
    refresh: () => fetch(true),
    setData: updateData,
  };
}
