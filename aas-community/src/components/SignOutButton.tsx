"use client";

import { signOut } from "next-auth/react";

export default function SignOutButton() {
  return (
    <button
      className="btn-ghost"
      onClick={() => signOut({ callbackUrl: "/" })}
      type="button"
    >
      Sign out
    </button>
  );
}
