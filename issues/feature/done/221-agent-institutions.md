---
id: FEAT-221
type: feature
priority: medium
status: done
---

# Backfill: agent institutions — skill docs, pre-push runner, CI failure-to-PR-comment channel

## Description

**As a** maintainer reading the issue corpus to understand
why the `skills/` directory and CI institutions exist
**I want** a FEAT that owns this work so traceability
isn't broken
**So that** every shipped artifact maps to an issue and
future audits don't flag the same gap.

Filed as a backfill per **AUDIT-2026-05-13**. The work was
shipped in commit `3870056` (PR #6 squash, "review: tests,
runtime fixes, CI feedback channel, agent institutions")
and tightened in commit `8a6e529` (PR #7, "subscribe +
end-turn; forbid polling CI"). Neither had an owning FEAT
at the time.

## What landed

### Skill documentation (`skills/`)

- `skills/testing.md` — three test layers (unit/SIT/PIT),
  pre-push hygiene, CI matrix, PR-comment failure channel.
- `skills/logging.md` — five-level logger contract,
  envvar gates, format invariant, `ACCOUNT_SOURCE_ONLY`
  test mode.
- `skills/bugs.md` — TDD-mandatory bug workflow.
- `skills/features.md` — feature workflow with user-story
  template.
- `skills/automerging.md` — auto-merge policy; PR #7's
  tightening to webhook-driven subscribe + end-turn lives
  here.

### Pre-push pipeline

- `tests/pre-push.sh` — environment-aware test runner
  (unit always; +SIT+PIT when a container engine is
  reachable).
- `.githooks/pre-push` — git-hook wrapper.
- `Makefile.in` `pre-push` and `install-hooks` targets.

### CI failure-to-PR-comment channel

- `tests/ci-post-failure.sh` — posts the failing job's log
  tail to the PR as a comment with a stable
  `<!-- ci-failure: <job> -->` marker.
- `.github/workflows/ci.yml` — `pull-requests: write`
  permission at the workflow level; every test-running
  job now tees output to `${{ runner.temp }}/<job>.log`
  and calls `ci-post-failure.sh` on failure.

### CLAUDE.md cross-references

- §3 rewritten to reference `skills/features.md` and
  `skills/bugs.md`.
- §9 (testing), §10 (logging), §11 (auto-merge),
  §12 (milestones and audits) added.

## Acceptance Criteria

Backfilled — these match the artifacts that actually shipped:

1. `skills/{testing,logging,bugs,features,automerging}.md`
   exist and are referenced from `CLAUDE.md`.
2. `tests/pre-push.sh` is executable, passes locally,
   and selects layers correctly across environments.
3. `tests/ci-post-failure.sh` is invoked from every
   test-running CI job under `if: failure()`.
4. `.github/workflows/ci.yml` declares
   `permissions: pull-requests: write` at the workflow
   level.
5. PR #6 (`3870056`) and PR #7 (`8a6e529`) are visible
   in `git log` as the shipping commits.

## Status

Done at filing time. Backfill record only.
