import type {
  AskRequest,
  AskResponse,
  ConversationTurn,
  EvalRunRequest,
  EvalRunResponse,
  HistoryDetail,
  HistorySummary,
} from "../types";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000";

async function request<TResponse>(path: string, init?: RequestInit): Promise<TResponse> {
  const res = await fetch(`${API_BASE_URL}${path}`, init);
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${res.status} ${res.statusText}: ${text}`);
  }
  return res.json() as Promise<TResponse>;
}

function postJson<TResponse>(path: string, body: unknown): Promise<TResponse> {
  return request<TResponse>(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

export function askQuestion(question: string, history: ConversationTurn[]): Promise<AskResponse> {
  const payload: AskRequest = { question, history };
  return postJson<AskResponse>("/api/qa/ask", payload);
}

export function runEval(evalFile?: string): Promise<EvalRunResponse> {
  const payload: EvalRunRequest = evalFile ? { eval_file: evalFile } : {};
  return postJson<EvalRunResponse>("/api/evals/run", payload);
}

export function listHistory(): Promise<HistorySummary[]> {
  return request<HistorySummary[]>("/api/history");
}

export function getHistoryRun(runId: string): Promise<HistoryDetail> {
  return request<HistoryDetail>(`/api/history/${runId}`);
}
