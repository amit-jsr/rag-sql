import { useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Play } from "lucide-react";
import { runEval } from "../api/client";
import Panel from "../components/Panel";
import MetricsDashboard from "../components/MetricsDashboard";
import EvalCaseDetail from "../components/EvalCaseDetail";
import type { EvalCaseResult } from "../types";

export default function EvalsPage() {
  const [selectedCase, setSelectedCase] = useState<EvalCaseResult | null>(null);
  const mutation = useMutation({ mutationFn: () => runEval() });

  const result = mutation.data;

  return (
    <div className="content">
      <Panel title="Eval run">
        <p className="panel-copy" style={{ marginTop: 0 }}>
          Runs the full pipeline against every question in the eval set and scores schema-linking
          precision/recall, execution accuracy (result-set comparison, not string match), valid-SQL
          rate, and repair-loop usage rate separately.
        </p>
        <button className="btn btn-primary" onClick={() => mutation.mutate()} disabled={mutation.isPending}>
          <Play size={14} />
          {mutation.isPending ? "Running eval…" : "Run eval set"}
        </button>
      </Panel>

      {mutation.isError && (
        <Panel title="Error">
          <p className="error-text">{(mutation.error as Error).message}</p>
        </Panel>
      )}

      {result && (
        <div className="section-gap reveal">
          <MetricsDashboard metrics={result.metrics} />

          <Panel title="Cases">
            <div className="table-scroll">
              <table className="tbl tbl-clickable">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Question</th>
                    <th>Difficulty</th>
                    <th>Valid SQL</th>
                    <th>Execution match</th>
                    <th className="cell-num">Repairs</th>
                  </tr>
                </thead>
                <tbody>
                  {result.cases.map((c) => (
                    <tr key={c.case_id} onClick={() => setSelectedCase(c)}>
                      <td className="mono-cell">{c.case_id}</td>
                      <td className="wrap-cell">{c.question}</td>
                      <td>
                        <span className="badge b-muted">
                          <span className="badge-dot" />
                          {c.difficulty}
                        </span>
                      </td>
                      <td>
                        {c.valid_sql ? (
                          <span className="badge b-green">
                            <span className="badge-dot" />
                            valid
                          </span>
                        ) : (
                          <span className="badge b-red">
                            <span className="badge-dot" />
                            invalid
                          </span>
                        )}
                      </td>
                      <td>
                        {c.execution_match ? (
                          <span className="badge b-green">
                            <span className="badge-dot" />
                            match
                          </span>
                        ) : (
                          <span className="badge b-red">
                            <span className="badge-dot" />
                            mismatch
                          </span>
                        )}
                      </td>
                      <td className="mono-cell cell-num">{c.retry_count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Panel>
        </div>
      )}

      {selectedCase && <EvalCaseDetail caseResult={selectedCase} onClose={() => setSelectedCase(null)} />}
    </div>
  );
}
