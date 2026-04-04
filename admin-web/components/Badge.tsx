interface Props {
  label: string;
  className?: string;
}

export default function Badge({ label, className = 'bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400' }: Props) {
  return (
    <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${className}`}>
      {label}
    </span>
  );
}
