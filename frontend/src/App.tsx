import { NavLink, Route, Routes, useLocation, Navigate } from "react-router-dom";
import { MessageSquareText, FlaskConical, History } from "lucide-react";
import QAPage from "./pages/QAPage";
import EvalsPage from "./pages/EvalsPage";
import HistoryPage from "./pages/HistoryPage";

const NAV_ITEMS = [
  { to: "/qa", label: "Q&A", icon: MessageSquareText },
  { to: "/history", label: "History", icon: History },
  { to: "/evals", label: "Evals", icon: FlaskConical },
];

const PAGE_META: Record<string, { title: string; sub: string }> = {
  "/qa": { title: "Q&A", sub: "Ask a question in plain English, get SQL + results" },
  "/evals": { title: "Evals", sub: "Score the pipeline against verified gold questions" },
  "/history": { title: "History", sub: "Every past run, logged automatically" },
};

export default function App() {
  const location = useLocation();
  const meta = PAGE_META[location.pathname] ?? PAGE_META["/qa"];

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="sidebar-logo">
          <div className="logo-row">
            <span className="logo-text">
              NexSql<span className="logo-slash">/</span>
            </span>
          </div>
        </div>
        <div className="nav-section">
          <div className="nav-label">Platform</div>
          {NAV_ITEMS.map(({ to, label, icon: Icon }) => (
            <NavLink key={to} to={to} className={({ isActive }) => `nav-btn${isActive ? " active" : ""}`}>
              <Icon size={16} strokeWidth={2} />
              {label}
            </NavLink>
          ))}
        </div>
        <div className="sidebar-bottom">
          <div className="status-row">
            <div className="pulse" />
            <span>NexForay Lab | © 2026</span>
          </div>
        </div>
      </aside>

      <main className="main">
        <div className="topbar">
          <div className="tb-left">
            <h1>
              <span>{meta.title}</span>
              <span className="title-sep">/</span>
              <span className="page-sub">{meta.sub}</span>
            </h1>
          </div>
          <div className="tb-right" />
        </div>
        <Routes>
          <Route path="/" element={<Navigate to="/qa" replace />} />
          <Route path="/qa" element={<QAPage />} />
          <Route path="/evals" element={<EvalsPage />} />
          <Route path="/history" element={<HistoryPage />} />
        </Routes>
      </main>
    </div>
  );
}
