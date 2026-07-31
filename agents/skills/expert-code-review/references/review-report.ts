/**
 * Expert Code Review — JSON output contract.
 * Schema version: 1.0.0
 *
 * The review report written to file MUST conform to ReviewReport.
 * No additional top-level keys. Enums are exhaustive.
 */

export const SCHEMA_VERSION = "1.0.0" as const;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

export type Severity = "blocker" | "major" | "minor" | "nit";

export type Verdict =
  | "approve"
  | "approve_with_comments"
  | "request_changes"
  | "reject";

export type FindingCategory =
  | "correctness"
  | "concurrency"
  | "security"
  | "error-handling"
  | "performance"
  | "maintainability"
  | "readability"
  | "testing"
  | "api-design"
  | "data-integrity"
  | "dependency"
  | "style";

export type ReviewDepth = "quick" | "standard" | "expert";

// ---------------------------------------------------------------------------
// Session / target
// ---------------------------------------------------------------------------

export interface ReviewTarget {
  repository?: string; // e.g. "org/payment-service"
  branch?: string;
  base_branch?: string;
  commits?: string[]; // short SHAs reviewed
  pull_request?: number;
  files?: string[]; // when reviewing loose files instead of a VCS range
}

export interface ReviewContext {
  language?: string; // primary language, e.g. "go", "typescript"
  frameworks?: string[];
  review_depth: ReviewDepth;
  focus_areas: FindingCategory[];
}

export interface Session {
  id: string; // e.g. "review-2026-07-31-001"
  reviewed_at: string; // ISO 8601 with timezone
  reviewer: string; // e.g. "expert-code-review"
  target: ReviewTarget;
  context: ReviewContext;
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

export interface FindingCounts {
  blocker: number;
  major: number;
  minor: number;
  nit: number;
}

export interface ReviewStats {
  files_reviewed: number;
  lines_added: number;
  lines_removed: number;
  findings_total: number;
  findings_by_severity: FindingCounts;
}

export interface Summary {
  verdict: Verdict; // derived per verdict rules — never freehand
  confidence: number; // 0..1, whole-review confidence
  overall_score: number; // 0..10, one decimal, per scoring rules
  one_liner: string; // <= 200 chars, states verdict reason
  stats: ReviewStats;
}

// ---------------------------------------------------------------------------
// Findings
// ---------------------------------------------------------------------------

export interface Location {
  file: string; // repo-relative path
  line_start: number;
  line_end: number;
  commit?: string;
  diff_hunk?: string | null; // e.g. "@@ -45,6 +45,18 @@"
}

export interface Finding {
  id: string; // "F-001", "F-002", ... sequential
  severity: Severity;
  category: FindingCategory;
  title: string; // one line, actionable
  location: Location;
  description: string; // what is wrong and why
  evidence: string; // required for blocker/major
  impact: string; // consequence if merged
  suggestion: string; // required for blocker/major
  suggested_patch?: string | null; // fenced code block when short & concrete
  references?: string[]; // URLs to docs/specs
  confidence: number; // 0..1; < 0.6 belongs in open_questions instead
}

export interface Positive {
  title: string;
  detail: string;
}

// ---------------------------------------------------------------------------
// Metrics, actions, questions
// ---------------------------------------------------------------------------

export interface Metrics {
  maintainability: number; // int 0..10
  readability: number; // int 0..10
  security: number; // int 0..10
  performance: number; // int 0..10
  test_coverage_delta?: string; // e.g. "+4.2%", "-1.0%"
}

export interface ActionItem {
  priority: number; // 1 = highest
  action: string;
  owner: "author" | "reviewer" | "team";
  blocks_merge: boolean;
  finding_refs: string[]; // e.g. ["F-001"]
}

export interface OpenQuestion {
  question: string;
  blocking: boolean;
  raised_by_finding?: string; // finding id
}

// ---------------------------------------------------------------------------
// Metadata / root
// ---------------------------------------------------------------------------

export interface Metadata {
  schema_version: typeof SCHEMA_VERSION;
  generator: string; // e.g. "expert-code-review"
  model?: string;
  duration_ms?: number;
  tokens_used?: number;
}

export interface ReviewReport {
  session: Session;
  summary: Summary;
  findings: Finding[];
  positives: Positive[];
  metrics: Metrics;
  action_items: ActionItem[];
  open_questions: OpenQuestion[];
  metadata: Metadata;
}
