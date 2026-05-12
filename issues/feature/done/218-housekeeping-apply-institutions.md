---
id: FEAT-218
type: feature
priority: medium
status: done
---

# Housekeeping: apply milestone + audit institutions to existing corpus

## Description

**As a** maintainer adopting `skills/milestones.md` and
`skills/audit.md`
**I want** the existing issue corpus brought into
compliance with both institutions in one shot
**So that** the new conventions are not theoretical — the
repo already demonstrates them from day one.

The first audit (`issues/audits/2026-05-12-first-audit.md`)
produced an Actions-taken list; this issue is the
implementation of that list.

## Implementation

Per AUDIT-2026-05-12:

1. **Close stale FEATs.** Set `status: done` on
   FEAT-022, FEAT-044, FEAT-197. Reasoning lives in the
   audit log.
2. **Keep FEAT-023 open** and add an audit-findings
   section to its body explaining which ACs are
   satisfied and which two are carried forward as
   FEAT-219 / FEAT-220 (to be filed in the next planning
   cycle).
3. **Move every `status: done` issue** under
   `issues/{bug,feature}/done/`:
   - bugs: 002, 003, 004, 005
   - features: 022, 044, 197, 208, 209, 210, 211, 212,
     213, 214, 215, plus this issue (218), FEAT-216, and
     FEAT-217.
4. **Delete completed ROADMAP files**:
   `issues/ROADMAP-1.1.0.md`, `…1.2.0.md`, `…1.3.0.md`.
5. **Open `ROADMAP-1.4.0.md`** listing FEAT-216,
   FEAT-217, FEAT-218 — all `done` in the same PR.

## Acceptance Criteria

1. `git ls-files issues/bug/*.md` returns no files (all
   bugs moved to `done/`).
2. `git ls-files issues/feature/*.md` returns only
   `023-account-self-contained-package.md` (the one
   still-open FEAT).
3. `issues/ROADMAP-1.1.0.md`, `ROADMAP-1.2.0.md`,
   `ROADMAP-1.3.0.md` are removed from the working tree.
4. `issues/ROADMAP-1.4.0.md` exists with three rows
   (FEAT-216, FEAT-217, FEAT-218), all marked `done`,
   and its own `status: done`.
5. `tests/pre-push.sh` still passes (83 unit tests).
