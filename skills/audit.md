---
name: audit
description: |
  Audit institution for the `account` package — periodic
  traceability checks that ensure every shipped behaviour
  is attached to a `FEAT-` or `BUG-` issue, and that every
  issue is attached to a shipped or in-flight artifact.
  Findings land in `issues/audits/<date>-<slug>.md`;
  uncovered functionality is filed as new issues; orphaned
  issues are closed or revived.
---

# `account` — audit institution

An audit is a deliberate walk through the package's public
surface (binaries, tests, docs, CI config) cross-referenced
with the issue corpus (`issues/{bug,feature}/` and their
`done/` archives). Its job is to keep traceability tight:
no shipped capability without an issue that authored it,
no issue without a clear shipped or in-flight status.

## 1. Cadence

| Trigger | Audit kind |
|---------|-----------|
| Closing a milestone | **post-milestone** — verify the ROADMAP's claims |
| Every N milestones (default: every 3) | **periodic** — full corpus walk |
| Suspicion of drift | **targeted** — one area, e.g. "is gpg/* covered?" |

A periodic audit is mandatory before a major version bump
(N → N+1 in semver). Skipping is allowed only when the
previous audit was less than one milestone old.

## 2. Inputs

The auditor walks five inputs:

1. **`bin/account`** — every `command:<verb>` function is a
   shipped capability.
2. **`tests/unit/*.bats`** — every `@test` block is a
   shipped behavioural contract.
3. **`share/man/man1/account.1`** — every documented
   subcommand is a published interface.
4. **`etc/bash_completion.d/account`** — every completion
   entry is a discoverable command.
5. **`.github/workflows/ci.yml`** — every job is a release
   gate.

Plus the corpus:

6. **`issues/{bug,feature}/<N>-*.md`** — open issues.
7. **`issues/{bug,feature}/done/<N>-*.md`** — closed
   issues (the archive).
8. **`issues/ROADMAP-*.md`** — open milestones.

## 3. Process

For each input artifact, identify:

- The **owning issue** — the `FEAT-NNN` or `BUG-NNN` that
  introduced or last revised it. Find it by `git log
  --follow <path>` and matching commit messages to issue
  ids.
- The **coverage status** — does at least one test exercise
  it? Is it documented in the man page? In `docs/account.md`?

Flag every artifact whose owning issue cannot be located.
Flag every issue whose status (`open`/`done`) disagrees
with its observed presence in the codebase. Flag every
ROADMAP row that references an issue not in the open or
done corpus.

## 4. Output: the audit log

Every audit produces a single file:

    issues/audits/<YYYY-MM-DD>-<slug>.md

Frontmatter:

    ---
    id: AUDIT-<YYYY-MM-DD>
    type: audit
    kind: post-milestone | periodic | targeted
    status: open | done
    ---

Body sections:

1. **Scope** — what was audited (which milestone, which
   files, which corpus).
2. **Method** — the inputs walked, in order.
3. **Findings** — bulleted, each with one of:
   - **OK** — artifact has an owning issue and matching
     coverage.
   - **MISSING-ISSUE** — artifact exists, no issue owns
     it. Action: file a backfill `FEAT-` or `BUG-`.
   - **MISSING-COVERAGE** — issue exists, artifact missing.
     Action: re-open the issue or file a new follow-up.
   - **STALE** — issue claims status that disagrees with
     the codebase. Action: correct the issue's status.
   - **ORPHAN-ROW** — ROADMAP row points to an unknown
     issue. Action: delete the row or restore the issue.
4. **Actions taken** — what the auditor did during the
   audit (filed which new issues, moved which to `done/`,
   re-opened which).
5. **Carried forward** — items the auditor flagged but
   did not fix; each becomes a new `FEAT-` or `BUG-`
   issue queued into the next planning ROADMAP.

The log's `status` flips to `done` only when every
**Actions taken** item has landed and every **Carried
forward** item has a corresponding issue id.

## 5. What a clean audit looks like

A passing audit emits ≥ one OK per artifact and zero of
the four flag categories. The log can be terse — a few
lines per section — when no findings are present.

A failing audit is not a failure of the package; it is
**the system working as intended**. Drift is normal; the
audit's job is to detect and document it. The actions it
emits feed the next planning cycle.

## 6. Cross-references

- Milestone institution → `skills/milestones.md`
- Feature workflow → `skills/features.md`
- Bug workflow → `skills/bugs.md`
- Test layers → `skills/testing.md`
- Auto-merge policy → `skills/automerging.md`
