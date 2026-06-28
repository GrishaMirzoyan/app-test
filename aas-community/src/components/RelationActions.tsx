"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RelationActions({
  memberId,
  relation,
}: {
  memberId: string;
  relation: "self" | "friends" | "pending" | "none";
}) {
  const [rel, setRel] = useState(relation);
  const [note, setNote] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  async function addFriend() {
    setBusy(true);
    try {
      const res = await fetch("/api/friends/request", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ addresseeId: memberId }),
      });
      if (res.ok) setRel("pending");
    } finally {
      setBusy(false);
    }
  }

  async function message() {
    setBusy(true);
    try {
      const res = await fetch("/api/chat/dm", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ memberId }),
      });
      const j = await res.json().catch(() => ({}));
      if (j.threadId) {
        router.push(`/chat/${j.threadId}`);
      } else if (j.requested) {
        // Message requests gate first contact from non-friends (§1).
        setNote("Message request sent — they'll see it in their inbox.");
      } else {
        setNote(j.error ?? "Could not start a conversation.");
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col items-end gap-2">
      <div className="flex gap-2">
        {rel === "none" && (
          <button className="btn-ghost" disabled={busy} onClick={addFriend} type="button">
            Add friend
          </button>
        )}
        {rel === "pending" && <span className="chip">Friend request pending</span>}
        {rel === "friends" && <span className="chip">Friends ✓</span>}
        <button className="btn" disabled={busy} onClick={message} type="button">
          Message
        </button>
      </div>
      {note && <p className="text-xs text-deep-700/60">{note}</p>}
    </div>
  );
}
