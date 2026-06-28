"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RequestInbox({
  messageRequests,
  friendRequests,
}: {
  messageRequests: { id: string; fromName: string }[];
  friendRequests: { requesterId: string; requesterName: string }[];
}) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);

  async function respondMessage(requestId: string, accept: boolean) {
    setBusy(true);
    try {
      const res = await fetch("/api/chat/message-request", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ requestId, accept }),
      });
      const j = await res.json().catch(() => ({}));
      if (j.threadId) router.push(`/chat/${j.threadId}`);
      else router.refresh();
    } finally {
      setBusy(false);
    }
  }

  async function respondFriend(requesterId: string, accept: boolean) {
    setBusy(true);
    try {
      await fetch("/api/friends/respond", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ requesterId, accept }),
      });
      router.refresh();
    } finally {
      setBusy(false);
    }
  }

  if (messageRequests.length === 0 && friendRequests.length === 0) {
    return (
      <div className="card">
        <h2 className="font-medium">Requests</h2>
        <p className="mt-1 text-xs text-deep-700/60">Nothing waiting.</p>
      </div>
    );
  }

  return (
    <div className="card space-y-3">
      <h2 className="font-medium">Requests</h2>

      {messageRequests.map((r) => (
        <div key={r.id} className="rounded-lg bg-ice-50 p-2 text-sm">
          <p>
            <span className="font-medium">{r.fromName}</span> wants to message you
          </p>
          <div className="mt-2 flex gap-2">
            <button
              className="btn"
              disabled={busy}
              onClick={() => respondMessage(r.id, true)}
              type="button"
            >
              Accept
            </button>
            <button
              className="btn-ghost"
              disabled={busy}
              onClick={() => respondMessage(r.id, false)}
              type="button"
            >
              Decline
            </button>
          </div>
        </div>
      ))}

      {friendRequests.map((r) => (
        <div key={r.requesterId} className="rounded-lg bg-ice-50 p-2 text-sm">
          <p>
            <span className="font-medium">{r.requesterName}</span> sent a friend
            request
          </p>
          <div className="mt-2 flex gap-2">
            <button
              className="btn"
              disabled={busy}
              onClick={() => respondFriend(r.requesterId, true)}
              type="button"
            >
              Accept
            </button>
            <button
              className="btn-ghost"
              disabled={busy}
              onClick={() => respondFriend(r.requesterId, false)}
              type="button"
            >
              Decline
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
