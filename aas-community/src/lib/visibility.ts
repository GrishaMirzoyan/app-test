// Privacy substrate helpers (§1, §4.8). Two privacy rings:
//   friends           — tighter ring for personal posts/memories
//   verified_members  — default in-app audience
//   hidden            — owner only
//
// These are pure functions; callers supply the relationship facts. The verification
// gate (gate.ts) is enforced separately and is a precondition for ANY sensitive read.

import type { Visibility } from "@prisma/client";

export interface Viewer {
  id: string;
  isVerified: boolean;
}

// Can `viewer` see an item owned by `ownerId` carrying `visibility`?
// `areFriends` must reflect an ACCEPTED friendship between viewer and owner.
export function canView(
  viewer: Viewer | null,
  ownerId: string,
  visibility: Visibility,
  areFriends: boolean,
): boolean {
  // Unverified accounts see nothing sensitive (verification gate, §1).
  if (!viewer || !viewer.isVerified) return false;

  // Owners always see their own content.
  if (viewer.id === ownerId) return true;

  switch (visibility) {
    case "hidden":
      return false;
    case "friends":
      return areFriends;
    case "verified_members":
      return true; // viewer is verified by the guard above
  }
}
