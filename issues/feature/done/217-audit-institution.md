---
id: FEAT-217
type: feature
priority: medium
status: done
---

# Audit institution: periodic traceability checks of shipped functionality

## Description

**As a** maintainer of a long-lived package
**I want** a documented audit cadence that walks every
shipped capability and verifies it is owned by a
`FEAT-` or `BUG-` issue
**So that** drift between "what the code does" and "what
the issue corpus says it does" is detected and corrected,
not allowed to accumulate.

The audit is not a one-off cleanup; it is a periodic
discipline. Outputs land in `issues/audits/<date>-*.md`
so the audit trail itself is permanent and searchable.

## Implementation

1. Write `skills/audit.md` covering:
   - Cadence (post-milestone / periodic / targeted).
   - Inputs (the five artifacts to walk + the corpus).
   - Process: identify owning issue + coverage status for
     each artifact; flag missing-issue / missing-coverage
     / stale / orphan-row.
   - Output: an audit log under `issues/audits/<date>-*.md`
     with frontmatter (kind, status) and five body
     sections (scope, method, findings, actions, carried
     forward).
   - What a clean audit looks like.

2. Run the **first audit** in this PR (see
   `issues/audits/2026-05-12-first-audit.md`) to validate
   the institution against real corpus state. Findings:
   - FEAT-022, FEAT-044, FEAT-197 are STALE (close).
   - FEAT-023 is PARTIAL (keep open, carry forward
     FEAT-219 and FEAT-220 as new follow-up issues).
   - The three completed ROADMAPs are ready to delete.
   - All `status: done` issues need to move to `done/`.

3. Cross-reference from CLAUDE.md §12.

## Acceptance Criteria

1. `skills/audit.md` exists with the cadence,
   inputs, process, and output-format sections.
2. `issues/audits/` directory exists with the first
   audit log dated 2026-05-12.
3. The audit log's "Actions taken" items are landed in
   the same PR (issues moved to `done/`, roadmaps
   deleted, stale FEATs closed).
4. CLAUDE.md §12 references the audit institution.
