interface Props {
  label: string;
  value: number | string;
  color?: string;
}

export default function StatsCard({ label, value, color = 'text-primary' }: Props) {
  return (
    <div className="bg-white dark:bg-dark-card rounded-xl p-5 text-center shadow-sm">
      <div className={`text-3xl font-extrabold ${color}`}>{value}</div>
      <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">{label}</div>
    </div>
  );
}
