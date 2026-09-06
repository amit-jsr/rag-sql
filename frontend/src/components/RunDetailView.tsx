import type { RunResult } from "../types";
import Panel from "./Panel";
import SQLDisplay from "./SQLDisplay";
import ResultTable from "./ResultTable";
import SchemaContextPanel from "./SchemaContextPanel";
import RepairTrace from "./RepairTrace";

interface RunDetailViewProps {
  result: RunResult;
}

export default function RunDetailView({ result }: RunDetailViewProps) {
  if (result.out_of_scope) {
    return (
      <Panel title="Out of scope">
        <p>{result.out_of_scope_reason ?? "This question can't be answered from the available schema."}</p>
      </Panel>
    );
  }

  return (
    <>
      <div className="stats">
        <div className="stat c-purple">
          <div className="stat-label">Tables retrieved</div>
          <div className="stat-val">{result.retrieved_tables.length}</div>
        </div>
        <div className="stat c-green">
          <div className="stat-label">Rows returned</div>
          <div className="stat-val">{result.rows.length}</div>
        </div>
        <div className={`stat ${result.retry_count > 0 ? "c-amber" : "c-green"}`}>
          <div className="stat-label">Repair attempts</div>
          <div className="stat-val">{result.retry_count}</div>
        </div>
      </div>

      <Panel
        title="Generated SQL"
        action={
          result.retry_count > 0 ? (
            <span className="badge b-amber">
              <span className="badge-dot" />
              {result.retry_count} repair(s)
            </span>
          ) : (
            <span className="badge b-green">
              <span className="badge-dot" />
              first try
            </span>
          )
        }
      >
        {result.sql ? <SQLDisplay sql={result.sql} /> : <p className="empty-state">No SQL generated.</p>}
        {result.error && <p className="error-text mt-sm">{result.error}</p>}
      </Panel>

      <Panel title="Result">
        <ResultTable columns={result.columns} rows={result.rows} />
      </Panel>

      <Panel title="Schema context">
        <SchemaContextPanel retrievedTables={result.retrieved_tables} linkedSchema={result.linked_schema} />
      </Panel>

      <Panel title="Repair trace">
        <RepairTrace trace={result.repair_trace} />
      </Panel>
    </>
  );
}
