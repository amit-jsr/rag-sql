interface ResultTableProps {
  columns: string[];
  rows: unknown[][];
  emptyMessage?: string;
}

function formatCell(value: unknown): string {
  if (value === null || value === undefined) return "—";
  return String(value);
}

function isNumericColumn(rows: unknown[][], colIndex: number): boolean {
  return rows.some((row) => typeof row[colIndex] === "number");
}

export default function ResultTable({ columns, rows, emptyMessage }: ResultTableProps) {
  if (rows.length === 0) {
    return <p className="empty-state">{emptyMessage ?? "No rows returned."}</p>;
  }

  const numericColumns = columns.map((_, i) => isNumericColumn(rows, i));

  return (
    <div className="table-scroll">
      <table className="tbl">
        <thead>
          <tr>
            {columns.map((col, i) => (
              <th key={col} className={numericColumns[i] ? "cell-num" : undefined}>
                {col}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i}>
              {row.map((value, j) => (
                <td key={j} className={`mono-cell${numericColumns[j] ? " cell-num" : ""}`}>
                  {formatCell(value)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
