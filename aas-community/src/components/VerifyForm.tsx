"use client";

import { useState } from "react";

export default function VerifyForm({
  vouches,
  threshold,
  openRequest,
}: {
  memberId: string;
  vouches: number;
  threshold: number;
  openRequest: { method: string; status: string } | null;
}) {
  const [method, setMethod] = useState<"vouch" | "era_corroboration">(
    (openRequest?.method as never) ?? "vouch",
  );
  const [details, setDetails] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [submitted, setSubmitted] = useState(openRequest?.status === "pending");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      const res = await fetch("/api/verification/request", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ method, corroborationDetails: details }),
      });
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? "Could not submit.");
      }
      setSubmitted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card space-y-4">
      <div>
        <div className="mb-1 flex items-center justify-between text-sm">
          <span className="font-medium">Vouch progress</span>
          <span>
            {vouches} / {threshold}
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-ice-100">
          <div
            className="h-full bg-deep-800 transition-all"
            style={{ width: `${Math.min(100, (vouches / threshold) * 100)}%` }}
          />
        </div>
        <p className="mt-2 text-xs text-deep-700/60">
          Once {threshold} verified Penguins vouch for you, you&apos;re in
          automatically.
        </p>
      </div>

      <div className="flex gap-2">
        <button
          type="button"
          className={method === "vouch" ? "btn" : "btn-ghost"}
          onClick={() => setMethod("vouch")}
        >
          Get vouched
        </button>
        <button
          type="button"
          className={method === "era_corroboration" ? "btn" : "btn-ghost"}
          onClick={() => setMethod("era_corroboration")}
        >
          Era corroboration (admin)
        </button>
      </div>

      <form onSubmit={submit} className="space-y-3">
        {method === "vouch" ? (
          <p className="text-sm text-deep-700/70">
            Ask Penguins who remember you to confirm you on their Vouch page.
            Submitting marks you as actively seeking vouches so they can find
            you.
          </p>
        ) : (
          <div>
            <label className="label">
              Details only a real Penguin would know
            </label>
            <textarea
              className="input min-h-[120px]"
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              placeholder="Principal names, teachers, campus details, era specifics…"
            />
          </div>
        )}

        {error && <p className="text-sm text-red-600">{error}</p>}
        {submitted ? (
          <p className="rounded-lg bg-ice-100 p-3 text-sm">
            Your request is in. {method === "vouch"
              ? "Waiting for peers to vouch."
              : "An admin will review your corroboration."}{" "}
            This page updates as it progresses — check back soon.
          </p>
        ) : (
          <button className="btn w-full" disabled={busy} type="submit">
            {busy ? "Submitting…" : "Submit request"}
          </button>
        )}
      </form>
    </div>
  );
}
