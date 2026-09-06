import type { RepairTraceEntry } from "../types";
import SQLDisplay from "./SQLDisplay";

interface RepairTraceProps {
  trace: RepairTraceEntry[];
}

export default function RepairTrace({ trace }: RepairTraceProps) {
  if (trace.length === 0) {
    return (
      <span className="badge b-green">
        <span className="badge-dot" />
        No repairs needed — succeeded on the first try
      </span>
    );
  }

  return (
    <div>
      {trace.map((entry) => (
        <div className="repair-step" key={entry.attempt}>
          <div className="mb-sm">
            <span className="badge b-amber">
              <span className="badge-dot" />
              Attempt {entry.attempt}
            </span>
          </div>
          <p className="error-text mb-sm">{entry.error}</p>
          <span className="mini-label">Repaired SQL</span>
          <SQLDisplay sql={entry.fixed_sql} />
        </div>
      ))}
    </div>
  );
}
