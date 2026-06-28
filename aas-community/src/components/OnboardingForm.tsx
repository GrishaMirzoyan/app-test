"use client";

import { useState } from "react";

type Role = "student" | "faculty" | "staff";
const DIVISIONS = ["elementary", "middle", "high"] as const;

export default function OnboardingForm({
  initial,
}: {
  initial: {
    role: Role;
    displayName: string;
    isPseudonymous: boolean;
    homeCity: string;
    homeCountry: string;
    mapVisibility: "city" | "country" | "hidden";
    span?: { startYear: number; endYear: number; graduated: boolean };
  };
}) {
  const [role, setRole] = useState<Role>(initial.role);
  const [displayName, setDisplayName] = useState(initial.displayName);
  const [isPseudonymous, setIsPseudonymous] = useState(initial.isPseudonymous);
  const [homeCity, setHomeCity] = useState(initial.homeCity);
  const [homeCountry, setHomeCountry] = useState(initial.homeCountry);
  const [mapVisibility, setMapVisibility] = useState(initial.mapVisibility);
  const [startYear, setStartYear] = useState(initial.span?.startYear ?? 2010);
  const [endYear, setEndYear] = useState(initial.span?.endYear ?? 2014);
  const [graduated, setGraduated] = useState(initial.span?.graduated ?? false);
  const [entryGrade, setEntryGrade] = useState("");
  const [exitGrade, setExitGrade] = useState("");
  const [divisions, setDivisions] = useState<string[]>([]);
  const [subjects, setSubjects] = useState("");
  const [gradesTaught, setGradesTaught] = useState("");
  const [staffRole, setStaffRole] = useState("");

  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  function toggleDivision(d: string) {
    setDivisions((cur) =>
      cur.includes(d) ? cur.filter((x) => x !== d) : [...cur, d],
    );
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      const res = await fetch("/api/onboarding", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          role,
          displayName,
          isPseudonymous,
          homeCity,
          homeCountry,
          mapVisibility,
          span: {
            startYear,
            endYear,
            entryGrade: entryGrade || null,
            exitGrade: exitGrade || null,
            graduated,
            divisions,
            subjects: subjects
              .split(",")
              .map((s) => s.trim())
              .filter(Boolean),
            gradesTaught: gradesTaught
              .split(",")
              .map((s) => s.trim())
              .filter(Boolean),
            staffRole: staffRole || null,
          },
        }),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? "Could not save.");
      }
      window.location.href = "/verify";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-5">
      <div className="card space-y-4">
        <div>
          <label className="label">I was a…</label>
          <div className="flex gap-2">
            {(["student", "faculty", "staff"] as Role[]).map((r) => (
              <button
                key={r}
                type="button"
                onClick={() => setRole(r)}
                className={role === r ? "btn" : "btn-ghost"}
              >
                {r[0].toUpperCase() + r.slice(1)}
              </button>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="label">First year</label>
            <input
              className="input"
              type="number"
              value={startYear}
              onChange={(e) => setStartYear(Number(e.target.value))}
            />
          </div>
          <div>
            <label className="label">Last year</label>
            <input
              className="input"
              type="number"
              value={endYear}
              onChange={(e) => setEndYear(Number(e.target.value))}
            />
          </div>
        </div>

        {role === "student" && (
          <>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Entry grade</label>
                <input
                  className="input"
                  value={entryGrade}
                  onChange={(e) => setEntryGrade(e.target.value)}
                  placeholder="PK, 5, 9…"
                />
              </div>
              <div>
                <label className="label">Exit grade</label>
                <input
                  className="input"
                  value={exitGrade}
                  onChange={(e) => setExitGrade(e.target.value)}
                  placeholder="12…"
                />
              </div>
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={graduated}
                onChange={(e) => setGraduated(e.target.checked)}
              />
              I graduated from AAS
            </label>
            <div>
              <label className="label">Divisions</label>
              <div className="flex gap-2">
                {DIVISIONS.map((d) => (
                  <button
                    key={d}
                    type="button"
                    onClick={() => toggleDivision(d)}
                    className={divisions.includes(d) ? "btn" : "btn-ghost"}
                  >
                    {d}
                  </button>
                ))}
              </div>
            </div>
          </>
        )}

        {role === "faculty" && (
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="label">Subjects (comma-separated)</label>
              <input
                className="input"
                value={subjects}
                onChange={(e) => setSubjects(e.target.value)}
                placeholder="Math, Physics"
              />
            </div>
            <div>
              <label className="label">Grades taught</label>
              <input
                className="input"
                value={gradesTaught}
                onChange={(e) => setGradesTaught(e.target.value)}
                placeholder="9, 10, 11"
              />
            </div>
          </div>
        )}

        {role === "staff" && (
          <div>
            <label className="label">Staff role</label>
            <input
              className="input"
              value={staffRole}
              onChange={(e) => setStaffRole(e.target.value)}
              placeholder="Librarian, Admissions…"
            />
          </div>
        )}
      </div>

      <div className="card space-y-4">
        <div>
          <label className="label">Display name</label>
          <input
            className="input"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            required
          />
          <label className="mt-2 flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={isPseudonymous}
              onChange={(e) => setIsPseudonymous(e.target.checked)}
            />
            This is a pseudonym (your legal name stays private, used only for
            verification)
          </label>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="label">Home city</label>
            <input
              className="input"
              value={homeCity}
              onChange={(e) => setHomeCity(e.target.value)}
              placeholder="City only — no street address"
              required
            />
          </div>
          <div>
            <label className="label">Country</label>
            <input
              className="input"
              value={homeCountry}
              onChange={(e) => setHomeCountry(e.target.value)}
              required
            />
          </div>
        </div>

        <div>
          <label className="label">Show me on the map as…</label>
          <select
            className="input"
            value={mapVisibility}
            onChange={(e) => setMapVisibility(e.target.value as never)}
          >
            <option value="city">A pin on my city</option>
            <option value="country">Only my country</option>
            <option value="hidden">Don&apos;t show me on the map</option>
          </select>
        </div>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}
      <button className="btn w-full" disabled={busy} type="submit">
        {busy ? "Saving…" : "Continue to verification"}
      </button>
    </form>
  );
}
