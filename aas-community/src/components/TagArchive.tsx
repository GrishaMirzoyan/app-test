"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

interface Hit {
  id: string;
  name: string;
  label: string;
}

export default function TagArchive({ archiveItemId }: { archiveItemId: string }) {
  const [label, setLabel] = useState("");
  const [q, setQ] = useState("");
  const [hits, setHits] = useState<Hit[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  async function search(value: string) {
    setQ(value);
    if (value.trim().length < 2) {
      setHits([]);
      return;
    }
    const res = await fetch(`/api/members/search?q=${encodeURIComponent(value)}`);
    const j = await res.json().catch(() => ({ members: [] }));
    setHits(j.members ?? []);
  }

  async function tag(body: { taggedMemberId?: string; label?: string }) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/archive/${archiveItemId}/tag`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? "Could not add tag.");
      }
      setLabel("");
      setQ("");
      setHits([]);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not add tag.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-3">
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label className="label">Tag a room or write a name</label>
          <div className="flex gap-2">
            <input
              className="input"
              value={label}
              onChange={(e) => setLabel(e.target.value)}
              placeholder="Hall of Flags, or a name"
            />
            <button
              className="btn"
              disabled={busy || !label.trim()}
              onClick={() => tag({ label: label.trim() })}
              type="button"
            >
              Add
            </button>
          </div>
        </div>
        <div>
          <label className="label">Name a face (a member)</label>
          <input
            className="input"
            value={q}
            onChange={(e) => search(e.target.value)}
            placeholder="Search members…"
          />
          {hits.length > 0 && (
            <ul className="mt-1 rounded-lg border border-ice-200 bg-white">
              {hits.map((h) => (
                <li key={h.id}>
                  <button
                    type="button"
                    disabled={busy}
                    onClick={() => tag({ taggedMemberId: h.id })}
                    className="block w-full px-3 py-2 text-left text-sm hover:bg-ice-100"
                  >
                    {h.name}{" "}
                    <span className="text-xs text-deep-700/60">{h.label}</span>
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <p className="text-xs text-deep-700/50">
        Members who&apos;ve opted out of face tagging can&apos;t be tagged.
      </p>
    </div>
  );
}
