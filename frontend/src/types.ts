// Mirrors backend/app/api/schemas.py — keep in sync with that file.

export interface RepairTraceEntry {
  attempt: number;
  failed_sql: string;
  error: string;
  fixed_sql: string;
}

export interface RetrievedTableOut {
  table: string;
  description: string;
  domain_cluster: string | null;
  score: number;
}

export interface TableRef {
  table: string;
  reason: string;
}

export interface ColumnRef {
  table: string;
  column: string;
}

export interface JoinSpec {
  left_table: string;
  left_column: string;
  right_table: string;
  right_column: string;
}

export interface FilterSpec {
  table: string;
  column: string;
  op: string;
  value: string;
}

export interface LinkedSchema {
  tables: TableRef[];
  columns: ColumnRef[];
  joins: JoinSpec[];
  filters: FilterSpec[];
  aggregation: string | null;
  out_of_scope: boolean;
  out_of_scope_reason: string | null;
}

export interface ConversationTurn {
  question: string;
  sql: string | null;
}

export interface AskRequest {
  question: string;
  history: ConversationTurn[];
}

// Shared shape for anything that renders a run's outcome — a live Q&A answer or a
// replayed history entry (see components/RunDetailView.tsx).
export interface RunResult {
  out_of_scope: boolean;
  out_of_scope_reason: string | null;
  retrieved_tables: RetrievedTableOut[];
  linked_schema: LinkedSchema | null;
  sql: string | null;
  error: string | null;
  columns: string[];
  rows: unknown[][];
  retry_count: number;
  repair_trace: RepairTraceEntry[];
}

export interface AskResponse extends RunResult {
  question: string;
  run_id: string;
}

export interface HistorySummary {
  run_id: string;
  timestamp: number;
  question: string;
  out_of_scope: boolean;
  sql: string | null;
  error: string | null;
  row_count: number;
  retry_count: number;
}

export interface HistoryDetail extends RunResult {
  question: string;
  run_id: string;
  timestamp: number;
}

export interface EvalMetrics {
  schema_linking_precision: number;
  schema_linking_recall: number;
  execution_accuracy: number;
  valid_sql_rate: number;
  repair_loop_usage_rate: number;
  total_cases: number;
}

export interface EvalCaseResult {
  case_id: string;
  question: string;
  difficulty: string;
  question_type: string;
  domain_cluster: string | null;
  gold_sql: string;
  generated_sql: string | null;
  gold_tables: string[];
  linked_tables: string[];
  valid_sql: boolean;
  execution_match: boolean;
  retry_count: number;
  error: string | null;
  gold_columns: string[];
  gold_rows: unknown[][];
  generated_columns: string[];
  generated_rows: unknown[][];
}

export interface EvalRunRequest {
  eval_file?: string;
}

export interface EvalRunResponse {
  run_id: string;
  metrics: EvalMetrics;
  cases: EvalCaseResult[];
}
