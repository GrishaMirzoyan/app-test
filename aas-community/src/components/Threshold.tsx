"use client";

import { useEffect, useState } from "react";
import { signIn } from "next-auth/react";

// The Threshold (§4.1): themed login + a loading screen showing the motto with a
// brief intentional hold — never masking a slow load. "Welcome back" on return.
export default function Threshold({
  oauth,
  returning,
}: {
  oauth: { google: boolean; apple: boolean };
  returning: boolean;
}) {
  const [held, setHeld] = useState(true);

  useEffect(() => {
    // Brief intentional hold (~1.2s) so the threshold feels like a threshold.
    const t = setTimeout(() => setHeld(false), 1200);
    return () => clearTimeout(t);
  }, []);

  if (held) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-deep-900 text-ice-100">
        <div className="text-5xl">🐧</div>
        <p className="mt-6 animate-pulse text-lg tracking-wide">
          {returning ? "Welcome back" : "Once a Penguin, Always a Penguin"}
        </p>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-deep-900 px-4">
      <div className="w-full max-w-md">
        <div className="mb-6 text-center text-ice-100">
          <div className="text-4xl">🐧</div>
          <h1 className="mt-3 text-2xl font-semibold">AAS Community</h1>
          <p className="mt-1 text-sm text-ice-300">
            Once a Penguin, Always a Penguin
          </p>
        </div>
        <div className="card">
          <AuthBox oauth={oauth} />
        </div>
        <p className="mt-4 text-center text-xs text-ice-300">
          A private community. Nothing here is public or search-indexed.
        </p>
      </div>
    </div>
  );
}

function AuthBox({ oauth }: { oauth: { google: boolean; apple: boolean } }) {
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [legalName, setLegalName] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      if (mode === "signup") {
        const res = await fetch("/api/register", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ email, password, legalName }),
        });
        if (!res.ok) {
          const j = await res.json().catch(() => ({}));
          throw new Error(j.error ?? "Could not create account.");
        }
      }
      const result = await signIn("credentials", {
        email,
        password,
        redirect: false,
      });
      if (result?.error) throw new Error("Incorrect email or password.");
      // Server-side redirect logic on "/" routes to onboarding/verify/dashboard.
      window.location.href = "/";
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div>
      <div className="mb-4 flex rounded-lg bg-ice-100 p-1 text-sm">
        <button
          className={`flex-1 rounded-md py-1.5 ${mode === "signin" ? "bg-white shadow-sm" : ""}`}
          onClick={() => setMode("signin")}
          type="button"
        >
          Sign in
        </button>
        <button
          className={`flex-1 rounded-md py-1.5 ${mode === "signup" ? "bg-white shadow-sm" : ""}`}
          onClick={() => setMode("signup")}
          type="button"
        >
          Create account
        </button>
      </div>

      <form onSubmit={submit} className="space-y-3">
        {mode === "signup" && (
          <div>
            <label className="label">Legal name (private)</label>
            <input
              className="input"
              value={legalName}
              onChange={(e) => setLegalName(e.target.value)}
              placeholder="Used only for verification"
              required
            />
          </div>
        )}
        <div>
          <label className="label">Email</label>
          <input
            className="input"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>
        <div>
          <label className="label">Password</label>
          <input
            className="input"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button className="btn w-full" disabled={busy} type="submit">
          {busy ? "…" : mode === "signin" ? "Enter" : "Create account"}
        </button>
      </form>

      {(oauth.google || oauth.apple) && (
        <>
          <div className="my-4 flex items-center gap-3 text-xs text-deep-700/50">
            <div className="h-px flex-1 bg-ice-200" /> or{" "}
            <div className="h-px flex-1 bg-ice-200" />
          </div>
          <div className="space-y-2">
            {oauth.google && (
              <button
                className="btn-ghost w-full"
                onClick={() => signIn("google", { callbackUrl: "/" })}
                type="button"
              >
                Continue with Google
              </button>
            )}
            {oauth.apple && (
              <button
                className="btn-ghost w-full"
                onClick={() => signIn("apple", { callbackUrl: "/" })}
                type="button"
              >
                Continue with Apple
              </button>
            )}
          </div>
        </>
      )}
    </div>
  );
}
