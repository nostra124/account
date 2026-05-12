---
name: bugs
description: |
  Bug workflow for the `account` package — strict test-driven:
  every bug must land a failing unit test before any fix
  touches `bin/`. Covers issue authoring, the TDD sequence,
  CI feedback via PR comments, and "done" criteria. Companion
  to `skills/features.md` and `skills/testing.md`.
---

# `account` — bug workflow

A bug is any defect in shipped behaviour: a wrong output, a
silent failure, a crash, a regression, a typo with downstream
consequences. The workflow below is **non-negotiable** for the
maintaining agent.

## 1. File the issue first

Path: `issues/bug/<NNN>-<slug>.md`. Numbering is sequential
within the bug namespace (see `issues/bug/` for the current
high-water mark). Frontmatter:

    ---
    id: BUG-NNN
    type: bug
    priority: high | medium | low
    status: open
    ---

Body sections, in order:

1. **Severity** — concrete impact on users / consumers.
2. **Observed** — exact reproduction with paths and line
   numbers, e.g. `bin/account:474`.
3. **Root cause** — the why, not just the what.
4. **Fix plan** — the minimal change. Reject "while we're at
   it" cleanup.
5. **Acceptance Criteria** — bullet list, every item
   verifiable by `tests/pre-push.sh`.

Bugs come before features at the same priority level when
choosing what to work on (per CLAUDE.md §3).

## 2. Write the failing test BEFORE the fix

This is the TDD contract. Sequence:

1. Add a test to `tests/unit/account.bats` (or the relevant
   layer) that pins the broken behaviour.
2. Run `tests/pre-push.sh` (or `bats tests/unit/account.bats`).
   The new test **must fail**. If it passes, the test isn't
   actually exercising the bug — rewrite it.
3. Commit the test alone (or stage it; either works as long as
   the fix doesn't sneak in).
4. Edit `bin/account` (or the affected file) to make the test
   pass.
5. Re-run `tests/pre-push.sh`. New test passes, no others
   regress.
6. Commit the fix, referencing the BUG-NNN id in the commit
   message subject line.

The "test first" rule has two specific exceptions:

- **Tooling bugs** in `tests/` or `.github/` themselves —
  there's no meaningful "test the test" layer.
- **Typo / spelling fixes** that are catchable by a CI lint
  step (e.g. BUG-005 had no per-test gate; the CI `grep`
  guard is the regression protection).

In both cases the issue must spell out *why* the test-first
rule is being skipped and what the alternative regression
guard is.

## 3. CI is the contract

Failures arrive as PR comments thanks to
`tests/ci-post-failure.sh` (see `skills/testing.md`). The
comment carries the failing job's log tail, so the responsible
agent can read the assertion that broke and trace it back to
the line in `bin/account`.

If a fix doesn't clear CI, **file another bug** rather than
piling onto the first. The first bug owns the regression test
for its specific failure mode; the second bug owns its own.
Don't conflate.

## 4. Closing a bug

Update the frontmatter `status: open` → `status: done` in
**the same commit as the fix**. If the bug is part of a
roadmap milestone, also tick the row in
`issues/ROADMAP-<version>.md`.

A bug is done when:

1. The test pinning the bug passes locally
   (`tests/pre-push.sh`).
2. CI is green (every job, including matrix cells, except
   ones explicitly tagged `continue-on-error: true` with a
   reason).
3. The issue frontmatter reads `status: done`.
4. The ROADMAP row reads `done` (if applicable).

## 5. Working from a CI-only failure

When CI fails on a platform you can't reproduce locally
(e.g. macOS APFS case-insensitivity for FEAT-214), the
PR-comment channel is your input. Read the comment, trace
the assertion to a line in the test file, then:

1. Decide whether the test should be guarded with a platform
   probe (preferred: keeps the assertion alive where it's
   meaningful) or whether the underlying behaviour should
   change to match the platform's contract.
2. Write the guard — usually a `skip` with a clear reason —
   or the behaviour change.
3. File a follow-up issue if the guarded path leaves a real
   gap.

This is *not* a TDD bypass: the failing CI run IS the failing
test. You just don't have to write a new one to reproduce it
— the platform-specific guard is the "fix" and the existing
test (now skipped on that platform) is the regression record.

## 6. Cross-references

- Test layers and pre-push hygiene → `skills/testing.md`
- Logging level conventions → `skills/logging.md`
- Feature workflow → `skills/features.md`
- Auto-merge process → `skills/automerging.md`
