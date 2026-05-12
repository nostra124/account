---
name: milestones
description: |
  Milestone institution for the `account` package — how
  versioned backlog files (`issues/ROADMAP-<X.Y.Z>.md`)
  govern the planning → implementation → close-out
  lifecycle. One milestone per session run; completed
  milestones are deleted (git history preserves them);
  completed issues are moved to `done/` (not deleted) so
  traceability from code to spec survives forever.
---

# `account` — milestone institution

Every change to `account` is planned through a milestone.
A milestone is a single `issues/ROADMAP-<version>.md`
backlog file naming the bugs and features that will land
in one named release.

## 1. Why versioned backlogs

The institution exists to make three things possible:

1. **Predictable releases.** A milestone names a target
   version. When every issue in it is `done`, the
   milestone itself is `done`, and the release is cut by
   `make package VERSION=<X.Y.Z>`.
2. **One thread of work per session.** An agent invocation
   picks up exactly one milestone, implements every issue
   in it, and lands the result. No "let me also do this
   other thing" — that's a separate milestone.
3. **Forever-traceability.** Every shipped behaviour is
   attached to an issue; every issue is attached to a
   milestone; every milestone shipped on a release. Code
   can be traced back to spec through commit history and
   the issue's `done/` subdirectory.

## 2. Lifecycle

### Plan
Future work is filed as `FEAT-NNN` (`skills/features.md`)
or `BUG-NNN` (`skills/bugs.md`) issues. When several
related issues are ready to be worked together, they are
grouped into a new `issues/ROADMAP-<X.Y.Z>.md` file
with `status: open`.

The version number comes from semver applied to the
package's `.rpk/version`:
- A bug-fix-only milestone bumps the patch.
- An additive-only milestone bumps the minor.
- A breaking-change milestone bumps the major.

### Implement
One session run implements one milestone end-to-end:

1. Open a draft PR (per `skills/automerging.md`).
2. For each issue listed in the ROADMAP:
   - Follow `skills/bugs.md` (TDD: failing test first) or
     `skills/features.md` (user story → tests → impl).
   - Update the issue's frontmatter to `status: done`
     **in the same commit** as the change.
   - Tick the ROADMAP row to `done`.
3. When the ROADMAP table is all `done`, update its own
   frontmatter to `status: done`.
4. Mark the PR ready; auto-merge. Per
   `skills/automerging.md`, subscribe to PR activity and
   end the turn — webhooks drive the rest.

### Close
After the PR merges to master:

1. **Move every `status: done` issue** from
   `issues/bug/<N>-<slug>.md` to
   `issues/bug/done/<N>-<slug>.md`, and similarly for
   features. Never delete.
2. **Delete the ROADMAP file.** Completed milestones are
   removed from the working tree; git history preserves
   them.
3. **Tag and ship.** `make package VERSION=<X.Y.Z>`
   appends to `.rpk/versions` and tags `v<X.Y.Z>`.

## 3. Shuffling between milestones

It is acceptable to move an issue from one open milestone
to another (re-prioritisation) or from a planned milestone
into a fresh one. When shuffling:

- Remove the issue's row from the source ROADMAP table.
- Add the same row to the destination ROADMAP table.
- Update the Delivery notes in both files if the
  removed/added issue affected ordering.
- Keep the issue's `id:` and frontmatter unchanged —
  only the ROADMAP membership changes.

A future audit (`skills/audit.md`) will flag any issue
that appears in two ROADMAPs simultaneously, or any
ROADMAP whose `done` row points to an issue still marked
`open`.

## 4. The two directories

| Location | Meaning |
|----------|---------|
| `issues/bug/<N>-*.md` | Bug, status `open` or in-progress |
| `issues/bug/done/<N>-*.md` | Bug, status `done`, archived |
| `issues/feature/<N>-*.md` | Feature, status `open` or in-progress |
| `issues/feature/done/<N>-*.md` | Feature, status `done`, archived |
| `issues/ROADMAP-<X.Y.Z>.md` | Open milestone |
| `issues/audits/<date>-*.md` | Audit log (see `skills/audit.md`) |

A `done/` issue is not deleted. The file path becomes the
permanent record of the work; the issue's content
documents the user story / bug context, the
acceptance criteria, and the fix.

## 5. ROADMAP file format

Same frontmatter as features and bugs, plus a `version:`
field:

    ---
    id: ROADMAP-<X.Y.Z>
    type: roadmap
    version: X.Y.Z
    priority: high | medium | low
    status: open | done
    ---

Body:

1. **Title** — `Release X.Y.Z — <one-line theme>`.
2. **Overview** — 1-3 paragraphs naming the goal.
3. **Issues table** — one row per included `FEAT-NNN` /
   `BUG-NNN`, columns: id, type, priority, title, status.
4. **Delivery notes** — ordering, dependencies, rationale
   for grouping, any "land before X" hints.

A row is updated to `done` the moment its target issue
flips. The ROADMAP itself is `done` only when every row
is.

## 6. Single-session discipline

The intent of "one milestone per session run" is to keep
context windows healthy:

- An agent picking up `ROADMAP-<X.Y.Z>.md` should be able
  to hold every referenced issue in working memory.
- The PR for a milestone closes the loop: it lands every
  issue in the ROADMAP and the ROADMAP itself.
- Stretch goals discovered mid-session become new issues
  in a future milestone, not additions to the current one.

If a milestone turns out to be larger than one session
can hold, split it: open `ROADMAP-<X.Y.Z>-pt-2.md` (or
bump to `X.Y.(Z+1)`) and move the unfinished rows. This
is shuffling (§3); the institution handles it cleanly.

## 7. Cross-references

- Feature workflow → `skills/features.md`
- Bug workflow → `skills/bugs.md`
- Audit institution → `skills/audit.md`
- Auto-merge policy → `skills/automerging.md`
- Test layers → `skills/testing.md`
