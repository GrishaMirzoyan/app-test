"use client";

import { useState } from "react";
import { signOut } from "next-auth/react";

export default function AccountActions() {
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);

  async function del() {
    setBusy(true);
    try {
      const res = await fetch("/api/account/delete", { method: "POST" });
      if (res.ok) await signOut({ callbackUrl: "/" });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card space-y-3">
      <h2 className="font-medium">Your data</h2>
      <div className="flex flex-wrap gap-2">
        <a className="btn-ghost" href="/api/account/export">
          Export my data
        </a>
        {!confirming ? (
          <button
            className="btn-ghost text-red-600"
            onClick={() => setConfirming(true)}
            type="button"
          >
            Delete my account
          </button>
        ) : (
          <div className="flex items-center gap-2">
            <span className="text-sm text-red-600">
              This removes your account, pins, tags, and posts. Sure?
            </span>
            <button className="btn" disabled={busy} onClick={del} type="button">
              {busy ? "…" : "Delete permanently"}
            </button>
            <button
              className="btn-ghost"
              onClick={() => setConfirming(false)}
              type="button"
            >
              Cancel
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
