// Tunable thresholds (§3.3, §5.1). Read from env with safe defaults.

export const VOUCH_THRESHOLD = parseInt(process.env.VOUCH_THRESHOLD ?? "2", 10);

// Phase 2 features gate behind a real member COUNT, never a date (§5.1).
export const PHASE2_MEMBER_THRESHOLD = parseInt(
  process.env.PHASE2_MEMBER_THRESHOLD ?? "150",
  10,
);
