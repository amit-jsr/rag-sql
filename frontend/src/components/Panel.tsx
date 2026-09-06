import type { ReactNode } from "react";

interface PanelProps {
  title: string;
  action?: ReactNode;
  children: ReactNode;
}

export default function Panel({ title, action, children }: PanelProps) {
  return (
    <div className="panel">
      <div className="panel-hd">
        <span className="panel-title">{title}</span>
        {action}
      </div>
      <div className="panel-body">{children}</div>
    </div>
  );
}
