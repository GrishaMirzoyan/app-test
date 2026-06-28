"use client";

import { useState } from "react";

export default function SettingsForm({
  initial,
}: {
  initial: {
    displayName: string;
    isPseudonymous: boolean;
    allowFaceTagging: boolean;
    mapVisibility: "city" | "country" | "hidden";
    homeCity: string;
    homeCountry: string;
  };
}) {
  const [s, setS] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function save(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setSaved(false);
    setError(null);
    try {
      const res = await fetch("/api/settings/profile", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(s),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? "Could not save.");
      }
      setSaved(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not save.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={save} className="card space-y-4">
      <h2 className="font-medium">Identity &amp; privacy</h2>

      <div>
        <label className="label">Display name</label>
        <input
          className="input"
          value={s.displayName}
          onChange={(e) => setS({ ...s, displayName: e.target.value })}
        />
        <label className="mt-2 flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={s.isPseudonymous}
            onChange={(e) => setS({ ...s, isPseudonymous: e.target.checked })}
          />
          This is a pseudonym
        </label>
      </div>

      <label className="flex items-center gap-2 text-sm">
        <input
          type="checkbox"
          checked={s.allowFaceTagging}
          onChange={(e) => setS({ ...s, allowFaceTagging: e.target.checked })}
        />
        Allow my face/name to be tagged in archive items
      </label>
      <p className="-mt-2 text-xs text-deep-700/60">
        Turning this off removes existing tags of you from view and blocks new
        ones.
      </p>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label">Home city</label>
          <input
            className="input"
            value={s.homeCity}
            onChange={(e) => setS({ ...s, homeCity: e.target.value })}
          />
        </div>
        <div>
          <label className="label">Country</label>
          <input
            className="input"
            value={s.homeCountry}
            onChange={(e) => setS({ ...s, homeCountry: e.target.value })}
          />
        </div>
      </div>

      <div>
        <label className="label">Map visibility</label>
        <select
          className="input"
          value={s.mapVisibility}
          onChange={(e) =>
            setS({ ...s, mapVisibility: e.target.value as typeof s.mapVisibility })
          }
        >
          <option value="city">Show a pin on my city</option>
          <option value="country">Only my country</option>
          <option value="hidden">Hide me from the map</option>
        </select>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="flex items-center gap-3">
        <button className="btn" disabled={busy} type="submit">
          {busy ? "Saving…" : "Save"}
        </button>
        {saved && <span className="text-sm text-green-700">Saved ✓</span>}
      </div>
    </form>
  );
}
