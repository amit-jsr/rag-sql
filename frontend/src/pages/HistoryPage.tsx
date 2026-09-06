import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Inbox, RefreshCw, X } from "lucide-react";
import { getHistoryRun, listHistory } from "../api/client";
import Panel from "../components/Panel";
import RunDetailView from "../components/RunDetailView";

function formatTimestamp(ts: number): string {
  return new Date(ts * 1000).toLocaleString();
}

export default function HistoryPage() {
  const [selectedRunId, setSelectedRunId] = useState<string | null>(null);

  const listQuery = useQuery({ queryKey: ["history"], queryFn: listHistory });
  const detailQuery = useQuery({
    queryKey: ["history", selectedRunId],
    queryFn: () => getHistoryRun(selectedRunId!),
    enabled: selectedRunId !== null,
  });

  return (
    <div className="content">
      <Panel
        title="Past runs"
        action={
          <button className="btn btn-ghost btn-sm" onClick={() => listQuery.refetch()}>
            <RefreshCw size={13} />
            Refresh
          </button>
        }
      >
        {listQuery.isLoading && <p className="empty-state">Loading…</p>}
        {listQuery.isError && <p className="error-text">{(listQuery.error as Error).message}</p>}
        {listQuery.data && listQuery.data.length === 0 && (
          <div className="empty">
            <div className="empty-icon">
              <Inbox />
            </div>
            <div className="empty-title">No runs yet</div>
            <div className="empty-sub">Ask a question on the Q&amp;A page — every run is logged here automatically.</div>
          </div>
        )}
        {listQuery.data && listQuery.data.length > 0 && (
          <div className="table-scroll reveal">
            <table className="tbl tbl-clickable">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Question</th>
                  <th>Status</th>
                  <th className="cell-num">Rows</th>
                  <th className="cell-num">Repairs</th>
                </tr>
              </thead>
              <tbody>
                {listQuery.data.map((run) => (
                  <tr key={run.run_id} onClick={() => setSelectedRunId(run.run_id)}>
                    <td className="mono-cell">{formatTimestamp(run.timestamp)}</td>
                    <td className="wrap-cell">{run.question}</td>
                    <td>
                      {run.out_of_scope ? (
                        <span className="badge b-muted">
                          <span className="badge-dot" />
                          out of scope
                        </span>
                      ) : run.error ? (
                        <span className="badge b-red">
                          <span className="badge-dot" />
                          error
                        </span>
                      ) : (
                        <span className="badge b-green">
                          <span className="badge-dot" />
                          ok
                        </span>
                      )}
                    </td>
                    <td className="mono-cell cell-num">{run.row_count}</td>
                    <td className="mono-cell cell-num">{run.retry_count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      {selectedRunId && (
        <div className="modal-overlay" onClick={() => setSelectedRunId(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-hd">
              <div>
                <div className="modal-title">Run detail</div>
                {detailQuery.data && <p className="modal-subtitle">{detailQuery.data.question}</p>}
              </div>
              <button className="modal-close" onClick={() => setSelectedRunId(null)} aria-label="Close">
                <X size={16} />
              </button>
            </div>
            <div className="modal-body">
              {detailQuery.isLoading && <p className="empty-state">Loading…</p>}
              {detailQuery.isError && <p className="error-text">{(detailQuery.error as Error).message}</p>}
              {detailQuery.data && <RunDetailView result={detailQuery.data} />}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
