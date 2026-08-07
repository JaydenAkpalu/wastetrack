"use client";

import dynamic from "next/dynamic";
import { useState, useEffect } from "react";
import { supabase } from "@/lib/supabase/client";

const LiveMap = dynamic(() => import("@/components/map/LiveMap"), {
  ssr: false,
});

export default function DashboardPage() {
  const [zones, setZones] = useState([]);

  useEffect(() => {
    async function fetchZones() {
      const { data } = await supabase.from("authorized_zones").select("*");
      setZones(data || []);
    }
    fetchZones();
  }, [])

  return (
    <div>
      <h1>Dashboard</h1>
      <LiveMap zones={zones}/>
    </div>
  );
}