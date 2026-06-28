"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function VouchButton({
  voucheeId,
  alreadyVouched,
}: {
  voucheeId: string;
  alreadyVouched: boolean;
}) {
  const [done, setDone] = useState(alreadyVouched);
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  async function vouch() {
    setBusy(true);
    try {
      const res = await fetch("/api/verification/vouch", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ voucheeId }),
      });
      if (res.ok) {
        setDone(true);
        router.refresh();
      }
    } finally {
      setBusy(false);
    }
  }

  if (done) return <span className="chip">Vouched ✓</span>;
  return (
    <button className="btn" disabled={busy} onClick={vouch} type="button">
      {busy ? "…" : "Vouch"}
    </button>
  );
}
