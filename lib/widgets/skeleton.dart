import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 스켈레톤 로딩 위젯
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252830) : const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF252830) : const Color(0xFFE8E8E8),
      highlightColor: isDark ? const Color(0xFF2E3140) : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

/// 게시글 카드 스켈레톤
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBox(width: 48, height: 18, borderRadius: 10),
                const SizedBox(width: 8),
                SkeletonBox(width: 60, height: 14, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 10),
            const SkeletonBox(height: 16, borderRadius: 6),
            const SizedBox(height: 6),
            SkeletonBox(width: 200, height: 14, borderRadius: 6),
            const SizedBox(height: 10),
            Row(
              children: [
                SkeletonBox(width: 40, height: 12, borderRadius: 6),
                const SizedBox(width: 12),
                SkeletonBox(width: 40, height: 12, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 게시판 목록 스켈레톤
class PostListSkeleton extends StatelessWidget {
  final int count;
  const PostListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const PostCardSkeleton(),
    );
  }
}

/// 홈 화면 스켈레톤
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 현재 교시 카드
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            // 시간표 카드
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            // 게시판 카드
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            // 최근 글
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// 채팅 목록 스켈레톤
class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return SkeletonShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(radius: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 80, height: 14, borderRadius: 6),
                    const SizedBox(height: 6),
                    const SkeletonBox(height: 12, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
