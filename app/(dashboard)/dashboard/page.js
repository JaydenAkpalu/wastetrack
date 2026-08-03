"use client";

import dynamic from "next/dynamic";

const LiveMap = dynamic(() => import("@/components/map/LiveMap"), {
  ssr: false,
});

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      <LiveMap />
    </div>
  );
}