import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Send, RotateCcw, Sparkles, Clock, X } from "lucide-react";
import { askQuestion, listHistory } from "../api/client";
import Panel from "../components/Panel";
import RunDetailView from "../components/RunDetailView";
import type { AskResponse, ConversationTurn, HistorySummary } from "../types";

function timeAgo(ts: number): string {
  const seconds = Math.max(0, Date.now() / 1000 - ts);
  if (seconds < 60) return "just now";
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

const SECTION_ORDER = ["Today", "Yesterday", "Earlier"] as const;

function sectionLabel(ts: number): (typeof SECTION_ORDER)[number] {
  const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const daysAgo = Math.floor((startOfDay(new Date()) - startOfDay(new Date(ts * 1000))) / 86400000);
  if (daysAgo <= 0) return "Today";
  if (daysAgo === 1) return "Yesterday";
  return "Earlier";
}

function groupBySection(runs: HistorySummary[]): [string, HistorySummary[]][] {
  const groups = new Map<string, HistorySummary[]>();
  for (const run of runs) {
    const label = sectionLabel(run.timestamp);
    const bucket = groups.get(label) ?? [];
    bucket.push(run);
    groups.set(label, bucket);
  }
  return SECTION_ORDER.filter((label) => groups.has(label)).map((label) => [label, groups.get(label)!]);
}

export default function QAPage() {
  const [question, setQuestion] = useState("");
  const [turns, setTurns] = useState<AskResponse[]>([]);
  const [showRecent, setShowRecent] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const queryClient = useQueryClient();

  const recentQuery = useQuery({ queryKey: ["history"], queryFn: listHistory, enabled: showRecent });

  const mutation = useMutation({
    mutationFn: (q: string) => {
      const history: ConversationTurn[] = turns.map((t) => ({ question: t.question, sql: t.sql }));
      return askQuestion(q, history);
    },
    onSuccess: (data) => {
      setTurns((prev) => [...prev, data]);
      setQuestion("");
      queryClient.invalidateQueries({ queryKey: ["history"] });
    },
  });

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [turns.length]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!question.trim()) return;
    mutation.mutate(question.trim());
  };

  const isFollowUp = turns.length > 0;
  const recentQuestions = recentQuery.data ?? [];
  const recentSections = groupBySection(recentQuestions);

  return (
    <div className="chat-page">
      <div className="chat-layout">
        {showRecent && (
          <aside className="chat-recent">
            <div className="chat-recent-hd">
              <span className="chat-recent-title">Recent questions</span>
              <button className="modal-close" onClick={() => setShowRecent(false)} aria-label="Hide recent questions">
                <X size={15} />
              </button>
            </div>
            <div className="chat-recent-body">
              {recentQuery.isLoading && <p className="empty-state">Loading…</p>}
              {recentQuestions.length === 0 && !recentQuery.isLoading && (
                <p className="empty-state">Nothing asked yet — your questions will show up here.</p>
              )}
              {recentSections.map(([label, runs]) => (
                <div key={label}>
                  <div className="recent-section-label">{label}</div>
                  {runs.map((run) => (
                    <button
                      key={run.run_id}
                      className="recent-item"
                      onClick={() => {
                        setQuestion(run.question);
                        setShowRecent(false);
                      }}
                    >
                      <div className="recent-item-q">{run.question}</div>
                      <div className="recent-item-meta">
                        <Clock size={11} />
                        {timeAgo(run.timestamp)}
                      </div>
                    </button>
                  ))}
                </div>
              ))}
            </div>
          </aside>
        )}

        <div className="chat-main">
          <div className="chat-messages">
            {turns.length === 0 && !mutation.isPending && !mutation.isError && (
              <div className="empty reveal">
                <div className="empty-icon">
                  <Sparkles />
                </div>
                <div className="empty-title">Ask anything about the insurance data</div>
                <div className="empty-sub">Type a question below to get started.</div>
              </div>
            )}

            {turns.map((turn, i) => (
              <div key={turn.run_id} className="section-gap reveal">
                <div className="thread-turn-hd">
                  <span className="badge b-blue">
                    <span className="badge-dot" />Q{i + 1}
                  </span>
                  <span className="thread-turn-question">{turn.question}</span>
                </div>
                <RunDetailView result={turn} />
              </div>
            ))}

            {mutation.isError && (
              <Panel title="Error">
                <p className="error-text">{(mutation.error as Error).message}</p>
              </Panel>
            )}

            <div ref={bottomRef} />
          </div>

          <div className="chat-footer">
            <form className="question-form" onSubmit={handleSubmit} style={{ display: "flex", gap: "0.5rem" }}>
              <button
                type="button"
                className="btn btn-ghost btn-icon"
                onClick={() => setShowRecent((v) => !v)}
                aria-label="Recent questions"
                title="Recent questions"
              >
                <Clock size={14} />
              </button>
              <input
                className="form-input chat-input"
                placeholder={isFollowUp ? "Ask a follow-up…" : "Ask a question about the insurance data…"}
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
              />
              <button className="btn btn-primary btn-pill" type="submit" disabled={mutation.isPending}>
                <Send size={14} />
                {mutation.isPending ? "Thinking…" : isFollowUp ? "Ask follow-up" : "Ask"}
              </button>
              {isFollowUp && (
                <button
                  type="button"
                  className="btn btn-ghost btn-pill"
                  onClick={() => {
                    setTurns([]);
                    mutation.reset();
                  }}
                >
                  <RotateCcw size={14} />
                  New conversation
                </button>
              )}
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
