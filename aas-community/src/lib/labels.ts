// Label derivation (§2, §3.2). The display label is derived at READ time from
// role + span (+ graduated) — never stored. Examples:
//   Alum · Class of 2021      (student, graduated, single-year-ish span)
//   Alum · 2017–2021          (student, did not graduate / multi-year)
//   Faculty · 2008–2016
//   Staff · 2010–2014

import type { Role } from "@prisma/client";

export interface SpanLike {
  startYear: number;
  endYear: number;
  graduated?: boolean | null;
}

export function deriveLabel(role: Role, span: SpanLike | undefined | null): string {
  if (!span) {
    // No attendance recorded yet — fall back to a role-only label.
    return role === "student" ? "Alum" : role === "faculty" ? "Faculty" : "Staff";
  }

  const range =
    span.startYear === span.endYear
      ? `${span.startYear}`
      : `${span.startYear}–${span.endYear}`;

  switch (role) {
    case "student":
      // A graduating student reads as "Class of {grad year}".
      return span.graduated ? `Alum · Class of ${span.endYear}` : `Alum · ${range}`;
    case "faculty":
      return `Faculty · ${range}`;
    case "staff":
      return `Staff · ${range}`;
  }
}

// Two spans overlap (era-overlap, §2) if their inclusive year ranges intersect.
// This is the primary discovery relation — NOT graduating class.
export function spansOverlap(a: SpanLike, b: SpanLike): boolean {
  return a.startYear <= b.endYear && b.startYear <= a.endYear;
}
