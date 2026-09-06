interface SQLDisplayProps {
  sql: string;
}

export default function SQLDisplay({ sql }: SQLDisplayProps) {
  return <pre className="sql-block">{sql}</pre>;
}
