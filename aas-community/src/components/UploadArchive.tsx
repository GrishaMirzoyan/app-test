"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function UploadArchive() {
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/archive/upload", {
        method: "POST",
        body: new FormData(e.currentTarget),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? "Upload failed.");
      }
      const j = await res.json();
      router.push(`/library/${j.id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Upload failed.");
    } finally {
      setBusy(false);
    }
  }

  if (!open) {
    return (
      <button className="btn" onClick={() => setOpen(true)} type="button">
        Upload to the archive
      </button>
    );
  }

  return (
    <form onSubmit={submit} className="card space-y-3">
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label className="label">Type</label>
          <select className="input" name="type" defaultValue="photo">
            <option value="photo">Photo</option>
            <option value="yearbook">Yearbook</option>
          </select>
        </div>
        <div>
          <label className="label">Title</label>
          <input className="input" name="title" placeholder="e.g. Hall of Flags, winter" />
        </div>
        <div>
          <label className="label">Year</label>
          <input className="input" name="year" type="number" placeholder="2011" />
        </div>
        <div>
          <label className="label">Room tag (optional)</label>
          <input className="input" name="roomTag" placeholder="Hall of Flags, Bolshoi…" />
        </div>
        <div>
          <label className="label">Or year range start</label>
          <input className="input" name="yearRangeStart" type="number" />
        </div>
        <div>
          <label className="label">Year range end</label>
          <input className="input" name="yearRangeEnd" type="number" />
        </div>
      </div>
      <div>
        <label className="label">Image</label>
        <input className="input" name="file" type="file" accept="image/*" required />
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex gap-2">
        <button className="btn" disabled={busy} type="submit">
          {busy ? "Uploading…" : "Upload"}
        </button>
        <button className="btn-ghost" type="button" onClick={() => setOpen(false)}>
          Cancel
        </button>
      </div>
    </form>
  );
}
