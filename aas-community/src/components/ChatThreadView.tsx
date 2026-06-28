"use client";

import { useEffect, useRef, useState, useCallback } from "react";

interface Msg {
  id: string;
  body: string;
  senderId: string;
  senderName: string;
  createdAt: string;
}

// Real-time delivery via polling. The transport is swappable for a WebSocket /
// managed pub-sub in production (§1, §4.7) — the message shape is identical.
export default function ChatThreadView({
  threadId,
  meId,
}: {
  threadId: string;
  meId: string;
}) {
  const [messages, setMessages] = useState<Msg[]>([]);
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const lastAt = useRef<string | null>(null);
  const bottom = useRef<HTMLDivElement>(null);

  const poll = useCallback(async () => {
    const url = lastAt.current
      ? `/api/chat/${threadId}/messages?after=${encodeURIComponent(lastAt.current)}`
      : `/api/chat/${threadId}/messages`;
    const res = await fetch(url);
    if (!res.ok) return;
    const j = await res.json();
    const incoming: Msg[] = j.messages ?? [];
    if (incoming.length) {
      setMessages((cur) => {
        const seen = new Set(cur.map((m) => m.id));
        const merged = [...cur, ...incoming.filter((m) => !seen.has(m.id))];
        return merged;
      });
      lastAt.current = incoming[incoming.length - 1].createdAt;
    }
  }, [threadId]);

  useEffect(() => {
    poll();
    const t = setInterval(poll, 3000);
    return () => clearInterval(t);
  }, [poll]);

  useEffect(() => {
    bottom.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    const body = text.trim();
    if (!body) return;
    setSending(true);
    setText("");
    try {
      await fetch(`/api/chat/${threadId}/messages`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ body }),
      });
      await poll();
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="card flex h-[60vh] flex-col p-0">
      <div className="flex-1 space-y-2 overflow-y-auto p-4">
        {messages.length === 0 && (
          <p className="text-center text-sm text-deep-700/50">
            No messages yet — say hello.
          </p>
        )}
        {messages.map((m) => {
          const mine = m.senderId === meId;
          return (
            <div key={m.id} className={`flex ${mine ? "justify-end" : "justify-start"}`}>
              <div
                className={`max-w-[75%] rounded-2xl px-3 py-2 text-sm ${
                  mine ? "bg-deep-800 text-white" : "bg-ice-100 text-deep-900"
                }`}
              >
                {!mine && (
                  <p className="mb-0.5 text-xs font-medium opacity-70">
                    {m.senderName}
                  </p>
                )}
                {m.body}
              </div>
            </div>
          );
        })}
        <div ref={bottom} />
      </div>
      <form onSubmit={send} className="flex gap-2 border-t border-ice-200 p-3">
        <input
          className="input"
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Message…"
        />
        <button className="btn" disabled={sending} type="submit">
          Send
        </button>
      </form>
    </div>
  );
}
