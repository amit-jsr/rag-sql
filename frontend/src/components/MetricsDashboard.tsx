import type { EvalMetrics } from "../types";

interface MetricsDashboardProps {
  metrics: EvalMetrics;
}

function pct(value: number): string {
  return `${Math.round(value * 100)}%`;
}

export default function MetricsDashboard({ metrics }: MetricsDashboardProps) {
  const tiles: { label: string; value: string; sub: string; color: "c-blue" | "c-green" | "c-amber" | "c-purple" }[] = [
    {
      label: "Execution accuracy",
      value: pct(metrics.execution_accuracy),
      sub: "result-set match vs. gold SQL",
      color: "c-green",
    },
    {
      label: "Valid-SQL rate",
      value: pct(metrics.valid_sql_rate),
      sub: "executed without error",
      color: "c-blue",
    },
    {
      label: "Linking precision",
      value: pct(metrics.schema_linking_precision),
      sub: "linked tables that were correct",
      color: "c-purple",
    },
    {
      label: "Linking recall",
      value: pct(metrics.schema_linking_recall),
      sub: "gold tables that were found",
      color: "c-purple",
    },
    {
      label: "Repair-loop usage",
      value: pct(metrics.repair_loop_usage_rate),
      sub: "cases needing 1+ retry",
      color: "c-amber",
    },
    {
      label: "Total cases",
      value: String(metrics.total_cases),
      sub: "questions in this run",
      color: "c-blue",
    },
  ];

  return (
    <div className="stats">
      {tiles.map((tile) => (
        <div className={`stat ${tile.color}`} key={tile.label}>
          <div className="stat-label">{tile.label}</div>
          <div className="stat-val">{tile.value}</div>
          <div className="stat-sub">{tile.sub}</div>
        </div>
      ))}
    </div>
  );
}
