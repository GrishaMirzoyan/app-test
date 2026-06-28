"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function AdminReviewButtons({ requestId }: { requestId: string }) {
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  async function act(decision: "approve" | "reject") {
    setBusy(true);
    try {
      const res = await fetch("/api/verification/review", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ requestId, decision }),
      });
      if (res.ok) router.refresh();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex gap-2">
      <button className="btn" disabled={busy} onClick={() => act("approve")} type="button">
        Approve
      </button>
      <button
        className="btn-ghost"
        disabled={busy}
        onClick={() => act("reject")}
        type="button"
      >
        Reject
      </button>
    </div>
  );
}
