"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function CohortStarter() {
  const [year, setYear] = useState<number>(2010);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  async function start() {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/chat/cohort", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ year }),
      });
      const j = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(j.error ?? "Could not start cohort chat.");
      router.push(`/chat/${j.threadId}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not start.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card">
      <h2 className="font-medium">Start a cohort chat</h2>
      <p className="mt-1 text-xs text-deep-700/60">
        Seed a group with everyone who was here in a given year.
      </p>
      <div className="mt-3 flex gap-2">
        <input
          className="input"
          type="number"
          value={year}
          onChange={(e) => setYear(Number(e.target.value))}
        />
        <button className="btn" disabled={busy} onClick={start} type="button">
          {busy ? "…" : "Start"}
        </button>
      </div>
      {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}
