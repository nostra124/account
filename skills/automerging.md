---
name: automerging
description: |
  Auto-merge policy for `account` PRs — when to enable, what
  checks gate merge, what to do on red CI, and the agent
  contract for keeping a PR green from open to merge without
  manual intervention.
---

# `account` — auto-merge policy

Auto-merge is the **default** for agent-authored PRs in this
repo. The agent opens a draft, pushes commits until CI is
green, marks the PR ready, and enables auto-merge. The
maintainer only steps in for review-blocking concerns —
everything else lands automatically when checks pass.

## 1. Required checks (the merge gate)

A PR cannot auto-merge until every required check is green:

| Check | Why it gates |
|-------|--------------|
| `lint (typos)` | Cheap typo/version-drift regression guard |
| `unit (linux)` | Default-runner unit pass |
| `unit (linux, root)` | EUID==0 sandbox path (FEAT-208) |
| `unit (macos)` | Darwin-kernel unit pass (FEAT-212) |
| `sit (ubuntu:latest)` | Linux SIT in stock Ubuntu |
| `sit (debian:stable-slim)` | Debian variant |
| `sit (fedora:latest)` | RPM-family variant |
| `sit (archlinux:latest)` | Rolling-release variant |
| `sit (alpine:latest)` | musl variant |
| `sit (darwin)` | macOS SIT |

The set is defined in `.github/workflows/ci.yml`. A job
tagged `continue-on-error: true` is **not** required; that
tag is a deliberate, time-limited exception that must
reference the open issue blocking its full enforcement.

## 2. Lifecycle

1. **Open as draft.** Every agent-authored PR starts as a
   draft. Drafts don't trigger reviewers and they can't
   auto-merge — perfect for "still pushing fixes" states.
2. **Push until CI is green locally and remotely.**
   `tests/pre-push.sh` is the local gate (see
   `skills/testing.md`); CI is the remote gate. If CI is red,
   work the failure following `skills/bugs.md` (file a BUG,
   write the failing test, fix, push) — don't bypass.
3. **Mark ready for review.** Once CI is green, flip the PR
   from draft to ready via the GitHub MCP server's
   `update_pull_request` tool (`draft: false`).
4. **Enable auto-merge.** Call `enable_pr_auto_merge` with
   `mergeMethod: SQUASH` (preferred) or `MERGE` if the PR's
   commit history is itself the documentation.
5. **Walk away.** When the last check turns green, GitHub
   merges. No manual `merge_pull_request` call needed.

## 3. Choosing a merge method

| Method | When |
|--------|------|
| `SQUASH` | Default. Keeps `master` linear and the PR title becomes the commit subject. |
| `MERGE` | When the per-commit history is itself the record (e.g. a ROADMAP rollup where each commit closes a separate issue). |
| `REBASE` | Avoid; agent commit history is generally not worth replaying. |

## 4. Reacting to CI failure on an auto-merge-armed PR

If a check goes red after auto-merge is enabled, GitHub holds
the merge. The agent's job:

1. Read the `<!-- ci-failure: <job> -->` comment posted by
   `tests/ci-post-failure.sh`. That's the failing assertion.
2. Follow `skills/bugs.md` §5 — write the platform guard or
   the behaviour change.
3. Push the fix. CI re-runs. When green, GitHub completes the
   merge.

Do **not** disable auto-merge unless the fix requires a
fundamentally different approach (e.g. moving to a new
branch, reverting the entire feature). When in doubt, ask
the maintainer.

## 5. The agent contract

When working in this repo and pushing changes:

1. After the first push, **open the PR as a draft** if one
   doesn't exist.
2. After every push, **check CI status** via the GitHub MCP
   server's `pull_request_read` tool (`method: get_check_runs`).
3. If CI is green, **mark ready** and **enable auto-merge**
   (squash) — unless the maintainer has explicitly indicated
   they want manual review first.
4. If CI is red, **investigate via the PR-comment channel**,
   file a BUG if the failure is novel, write the failing test
   first, push the fix.
5. Subscribe to the PR's activity (`subscribe_pr_activity`)
   so subsequent CI events wake the session. Do not poll.

## 6. When to NOT auto-merge

- The PR touches `bin/account`'s public command surface in a
  way the maintainer hasn't explicitly approved.
- The PR removes or downgrades a runtime dependency.
- The PR force-pushes over a branch the maintainer has been
  reviewing.
- Any change to `.github/workflows/ci.yml` that loosens a
  required check.

In these cases, push as draft, mention the concern in the PR
body, and wait for explicit human approval.

## 7. Cross-references

- Test layers and pre-push hygiene → `skills/testing.md`
- Bug workflow (TDD) → `skills/bugs.md`
- Feature workflow → `skills/features.md`
- Logging conventions → `skills/logging.md`
