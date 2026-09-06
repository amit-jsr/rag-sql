import type { LinkedSchema, RetrievedTableOut } from "../types";

interface SchemaContextPanelProps {
  retrievedTables: RetrievedTableOut[];
  linkedSchema: LinkedSchema | null;
}

export default function SchemaContextPanel({ retrievedTables, linkedSchema }: SchemaContextPanelProps) {
  const linkedTableNames = new Set(linkedSchema?.tables.map((t) => t.table) ?? []);

  return (
    <div className="two-col">
      <div>
        <span className="mini-label">Retrieved tables</span>
        {retrievedTables.length === 0 ? (
          <p className="empty-state">No tables retrieved.</p>
        ) : (
          <div className="chip-row">
            {retrievedTables.map((t) => (
              <span
                key={t.table}
                className={`chip${linkedTableNames.has(t.table) ? " active" : ""}`}
                title={t.description}
              >
                {t.table} · {t.score.toFixed(2)}
              </span>
            ))}
          </div>
        )}
      </div>
      <div>
        <span className="mini-label">Linked schema</span>
        {!linkedSchema || linkedSchema.tables.length === 0 ? (
          <p className="empty-state">Nothing linked.</p>
        ) : (
          <>
            <div className="chip-row" style={{ marginBottom: "0.5rem" }}>
              {linkedSchema.tables.map((t) => (
                <span key={t.table} className="chip" title={t.reason}>
                  {t.table}
                </span>
              ))}
            </div>
            {linkedSchema.joins.length > 0 && (
              <div className="mono" style={{ fontSize: "0.78rem", color: "var(--muted)" }}>
                {linkedSchema.joins.map((j, i) => (
                  <div key={i}>
                    {j.left_table}.{j.left_column} = {j.right_table}.{j.right_column}
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
