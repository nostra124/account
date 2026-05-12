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
2. **Immediately call `subscribe_pr_activity`** for the PR.
   The subscription is idempotent (safe to call on every
   push). CI completion events for *both* success and
   failure conclusions arrive as `<github-webhook-activity>`
   messages and wake the session.
3. **End the turn**. Do not poll. Do not sleep. Do not
   repeatedly read `get_check_runs`. The session is webhook-
   driven from here.
4. When the webhook for a CI completion arrives:
   - **Green** (or PR reports `clean` status): if a previous
     `enable_pr_auto_merge` call returned "already in clean
     status", call `merge_pull_request` directly (squash).
     Otherwise mark the PR ready (`update_pull_request
     draft: false`) and call `enable_pr_auto_merge`.
   - **Red**: read the `<!-- ci-failure: <job> -->` comment
     posted by `tests/ci-post-failure.sh`, follow
     `skills/bugs.md` (file BUG → write failing test →
     fix → push). The new push triggers a new CI run; the
     subscription is still active so the next webhook will
     wake the session again.
5. The session is "done" when:
   - the PR is merged (the
     `<github-webhook-activity>` "merged" event auto-
     unsubscribes), **or**
   - the maintainer explicitly says to stop.

   Anything else — pending checks, partial successes, a
   single-job failure with the fix in flight — means the
   contract is still active. The agent waits for the next
   webhook; the session does not "hang" because a webhook
   will arrive (success, failure, or timeout-equivalent).

### Why not poll?

Polling burns tokens, races against GitHub's eventual-
consistency on combined-status fields, and produces wrong
answers when a check transitions between calls.
`get_check_runs` is fine for a *one-shot* read inside a
single turn (e.g. right after opening the PR, to see what
state we're starting from). It is the wrong tool for
"waiting until CI completes" — webhooks are.

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
