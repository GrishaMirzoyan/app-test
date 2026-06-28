"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

interface Entry {
  id: string;
  kind: "work" | "education";
  org: string;
  title: string;
  startYear: number | null;
  endYear: number | null;
  visibility: "friends" | "verified_members" | "hidden";
}

export default function ProfileEntriesManager({ entries }: { entries: Entry[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({
    kind: "work" as "work" | "education",
    org: "",
    title: "",
    startYear: "",
    endYear: "",
    visibility: "verified_members" as Entry["visibility"],
  });

  async function add(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await fetch("/api/profile-entry", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          kind: form.kind,
          org: form.org,
          title: form.title,
          startYear: form.startYear ? Number(form.startYear) : null,
          endYear: form.endYear ? Number(form.endYear) : null,
          visibility: form.visibility,
        }),
      });
      setForm({ ...form, org: "", title: "", startYear: "", endYear: "" });
      router.refresh();
    } finally {
      setBusy(false);
    }
  }

  async function remove(id: string) {
    setBusy(true);
    try {
      await fetch("/api/profile-entry", {
        method: "DELETE",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ id }),
      });
      router.refresh();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card space-y-4">
      <h2 className="font-medium">Work &amp; education</h2>

      <ul className="space-y-2">
        {entries.map((e) => (
          <li
            key={e.id}
            className="flex items-center justify-between rounded-lg bg-ice-50 p-2 text-sm"
          >
            <span>
              <span className="font-medium">{e.title}</span> · {e.org}{" "}
              <span className="text-deep-700/60">
                {e.startYear ?? ""}
                {e.startYear || e.endYear ? "–" : ""}
                {e.endYear ?? (e.startYear ? "present" : "")}
              </span>
              <span className="chip ml-2">{e.visibility}</span>
            </span>
            <button
              className="text-xs text-red-600 underline"
              disabled={busy}
              onClick={() => remove(e.id)}
              type="button"
            >
              Remove
            </button>
          </li>
        ))}
        {entries.length === 0 && (
          <li className="text-sm text-deep-700/60">No entries yet.</li>
        )}
      </ul>

      <form onSubmit={add} className="grid gap-2 sm:grid-cols-2">
        <select
          className="input"
          value={form.kind}
          onChange={(e) => setForm({ ...form, kind: e.target.value as "work" | "education" })}
        >
          <option value="work">Work</option>
          <option value="education">Education</option>
        </select>
        <select
          className="input"
          value={form.visibility}
          onChange={(e) =>
            setForm({ ...form, visibility: e.target.value as Entry["visibility"] })
          }
        >
          <option value="verified_members">Verified members</option>
          <option value="friends">Friends only</option>
          <option value="hidden">Hidden</option>
        </select>
        <input
          className="input"
          placeholder="Title / role or degree"
          value={form.title}
          onChange={(e) => setForm({ ...form, title: e.target.value })}
          required
        />
        <input
          className="input"
          placeholder="Organization / school"
          value={form.org}
          onChange={(e) => setForm({ ...form, org: e.target.value })}
          required
        />
        <input
          className="input"
          type="number"
          placeholder="Start year"
          value={form.startYear}
          onChange={(e) => setForm({ ...form, startYear: e.target.value })}
        />
        <input
          className="input"
          type="number"
          placeholder="End year (blank = current)"
          value={form.endYear}
          onChange={(e) => setForm({ ...form, endYear: e.target.value })}
        />
        <button className="btn sm:col-span-2" disabled={busy} type="submit">
          Add entry
        </button>
      </form>
    </div>
  );
}
