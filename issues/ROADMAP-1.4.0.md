---
id: ROADMAP-1.4.0
type: roadmap
version: 1.4.0
priority: medium
status: done
---

# Release 1.4.0 — milestone + audit institutions; corpus housekeeping

Promote the planning, traceability, and audit conventions
that ROADMAP-1.1.0 / 1.2.0 / 1.3.0 demonstrated by example
into named institutions documented under `skills/`. Apply
those institutions to the existing issue corpus in the same
PR: move every closed issue into `done/`, delete the three
completed ROADMAP files, file the first audit log.

## Issues

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [FEAT-216](./feature/done/216-milestone-institution.md) | feature | medium | Milestone institution: versioned backlogs in `issues/ROADMAP-<X.Y.Z>.md` | done |
| [FEAT-217](./feature/done/217-audit-institution.md) | feature | medium | Audit institution: periodic traceability checks of shipped functionality | done |
| [FEAT-218](./feature/done/218-housekeeping-apply-institutions.md) | feature | medium | Housekeeping: apply milestone + audit institutions to existing corpus | done |

## Delivery notes

- All three issues land together: the institutions
  (FEAT-216 + 217) are useless without their first
  application (FEAT-218), and the first application would
  have nothing to point at without the institution docs.
- The first audit log
  (`issues/audits/2026-05-12-first-audit.md`) closes
  FEAT-217's "first audit" obligation and carries forward
  two follow-up issues (FEAT-219, FEAT-220) for the next
  planning cycle. Those follow-ups will be filed when their
  target ROADMAP opens — they are NOT part of this
  milestone.
- After this PR merges, this `ROADMAP-1.4.0.md` file is
  itself deleted per `skills/milestones.md` (§ Close).
  Git history preserves the record.
