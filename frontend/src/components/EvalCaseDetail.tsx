import { X } from "lucide-react";
import type { EvalCaseResult } from "../types";
import SQLDisplay from "./SQLDisplay";
import ResultTable from "./ResultTable";

interface EvalCaseDetailProps {
  caseResult: EvalCaseResult;
  onClose: () => void;
}

export default function EvalCaseDetail({ caseResult, onClose }: EvalCaseDetailProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-hd">
          <div>
            <div className="modal-title">{caseResult.case_id}</div>
            <p className="modal-subtitle">{caseResult.question}</p>
          </div>
          <button className="modal-close" onClick={onClose} aria-label="Close">
            <X size={16} />
          </button>
        </div>
        <div className="modal-body">
          <div className="chip-row">
            <span className="badge b-muted">
              <span className="badge-dot" />
              {caseResult.difficulty}
            </span>
            <span className="badge b-muted">
              <span className="badge-dot" />
              {caseResult.question_type}
            </span>
            {caseResult.execution_match ? (
              <span className="badge b-green">
                <span className="badge-dot" />
                execution match
              </span>
            ) : (
              <span className="badge b-red">
                <span className="badge-dot" />
                execution mismatch
              </span>
            )}
            {caseResult.valid_sql ? (
              <span className="badge b-green">
                <span className="badge-dot" />
                valid SQL
              </span>
            ) : (
              <span className="badge b-red">
                <span className="badge-dot" />
                invalid SQL
              </span>
            )}
            {caseResult.retry_count > 0 && (
              <span className="badge b-amber">
                <span className="badge-dot" />
                {caseResult.retry_count} repair(s)
              </span>
            )}
          </div>

          <div className="two-col">
            <div>
              <span className="mini-label">Gold SQL</span>
              <SQLDisplay sql={caseResult.gold_sql} />
              <div className="mt-sm">
                <ResultTable columns={caseResult.gold_columns} rows={caseResult.gold_rows} />
              </div>
            </div>
            <div>
              <span className="mini-label">Generated SQL</span>
              <SQLDisplay sql={caseResult.generated_sql ?? "(no SQL generated)"} />
              <div className="mt-sm">
                <ResultTable columns={caseResult.generated_columns} rows={caseResult.generated_rows} />
              </div>
            </div>
          </div>

          {caseResult.error && <p className="error-text">{caseResult.error}</p>}
        </div>
      </div>
    </div>
  );
}
