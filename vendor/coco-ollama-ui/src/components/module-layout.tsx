"use client";

import { Sidebar } from "./sidebar";

interface ModuleLayoutProps {
  children: React.ReactNode;
}

export default function ModuleLayout({ children }: ModuleLayoutProps) {
  return (
    <div className="h-screen w-full flex">
      <div className="hidden md:block w-[280px] border-r">
        <Sidebar isCollapsed={false} messages={[]} isMobile={false} chatId="" />
      </div>
      <div className="flex-1 overflow-y-auto">{children}</div>
    </div>
  );
}
