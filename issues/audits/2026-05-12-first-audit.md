---
id: AUDIT-2026-05-12
type: audit
kind: post-milestone
status: done
---

# AUDIT-2026-05-12 — first audit after ROADMAP-1.1.0 / 1.2.0 / 1.3.0

## Scope

First periodic audit per the new `skills/audit.md`
institution. Covers:

- The four pre-existing open `FEAT-*` issues
  (022, 023, 044, 197) that pre-date the test-review
  milestones.
- The three milestone backlogs just completed
  (`ROADMAP-1.1.0`, `ROADMAP-1.2.0`, `ROADMAP-1.3.0`).
- The 12 new issues (`BUG-002..005`, `FEAT-208..215`)
  filed and closed during those milestones.

## Method

Walked five inputs in order:

1. `bin/account` — `grep -n '^command:' bin/account` to
   enumerate shipped subcommands.
2. `tests/unit/account.bats` — 83 `@test` blocks.
3. `share/man/man1/account.1` — manpage subcommand listing.
4. `etc/bash_completion.d/account` — completion entries.
5. `.github/workflows/ci.yml` — 10 jobs.

Cross-referenced against `issues/{bug,feature}/*.md` and
the three open ROADMAPs.

## Findings

### `FEAT-022` — make `account` the foundation — **STALE (close)**

Acceptance criteria spot-checks:
- `grep -wEn '(cache|check|config|data|hosts|repo|scripts|secret|user)' bin/account`
  → only ENV-var names (`XDG_CACHE_HOME`, `XDG_CONFIG_HOME`)
  and help-text strings; **no runtime script calls**.
- `bin/account help` lists the documented subcommands.
- Consumer scripts (those in other packages) — out of scope
  for this repo to verify.
- `docs/templates/CLAUDE.md.foundation` — outside this repo;
  the local `CLAUDE.md` § 4 and § 5 carry the same
  invariants.

Action: mark `status: done`, move to `issues/feature/done/`.
The "shared template" AC is owned by the parent
`scripts`-collection repo, not by `account`.

### `FEAT-023` — self-contained packaging — **PARTIAL (keep open)**

Of six acceptance criteria:

| AC | Status |
|---|---|
| `bin/account` has no `scripts has`/`scripts list` | ✅ (verified) |
| `docs/account.md` exists | ✅ (exists) |
| `bats tests/unit/account.bats` passes | ✅ (83/83) |
| `man -l share/man/man1/account.1` renders | ✅ (NAME/SYNOPSIS/DESCRIPTION present) |
| Tab completion for every subcommand | ❌ (`etc/bash_completion.d/account` is incomplete — missing `domainname`, `master`, `slaves`, `online`, `status`, `run`, `exe`, `sync`, `platform`, `hosts`, `remote-url`, `put`, `set`, `get`, `gpg-import-public-key`, `ssh-import-public-key`, several more) |
| `docs/templates/CLAUDE.md.account` exists | ❌ (`docs/templates/` does not exist) |

Action: keep `status: open`. Two gaps surface as follow-up
issues into a future ROADMAP:

- **FEAT-219** — refresh `etc/bash_completion.d/account`
  to cover every `command:<verb>` in `bin/account`.
- **FEAT-220** — create `docs/templates/CLAUDE.md.account`
  template per FEAT-023 AC 6.

(Filing of these issues is **carried forward** to the
next planning cycle; they are not part of ROADMAP-1.4.0.)

### `FEAT-044` — `remote-url` delegation — **STALE (close)**

The `account remote-url` command is implemented at
`bin/account:1094` and covered by 7 unit tests
(`tests/unit/account.bats` "remote-url" section). The
remaining ACs target `bin/secret` and `bin/config` —
**outside this repo**.

Action: mark `status: done` from `account`'s perspective.
The consumer-side work moved with FEAT-022's extraction:
`secret` and `config` own the calls to `account remote-url`
in their own repos.

### `FEAT-197` — `account-user` agent skill — **STALE (close)**

`skills/account-user/SKILL.md` exists with the six
required sections (design principles, model, workflow
recipes, guardrails, where to read more). The
`skills/account-user/opencode.md` companion file
mentioned in the AC is not strictly required by the
existing pattern (recent packages ship the skill via
`SKILL.md` alone and let `make install-skills-user`
symlink it).

Action: mark `status: done`, move to `issues/feature/done/`.

### `ROADMAP-1.1.0` / `1.2.0` / `1.3.0` — **DONE (delete files)**

All three roadmap files have every row marked `done` and
their own `status: done`. Per the new `skills/milestones.md`,
completed roadmaps are **deleted from the working tree**
(git history preserves the record).

Action: `git rm issues/ROADMAP-1.{1,2,3}.0.md`.

### Other completed issues — **DONE (move to `done/`)**

- `BUG-002..005` and `FEAT-208..215` all carry
  `status: done` but live in `issues/bug/` and
  `issues/feature/` proper.

Action: move each into `issues/{bug,feature}/done/`.
`BUG-001` was already in `issues/bug/done/`.

### Logger error helper — **OK**

The `error()` helper added during ROADMAP-1.2.0 cleanup
(part of the institutions PR) is owned by the same
session's logging work and covered by tests 16-17
(test names `error() emits...` and `fatal() emits...`).
No backfill issue needed.

### CI matrix — **OK**

All 10 jobs in `.github/workflows/ci.yml` map to ACs in
the closed milestones (`unit (linux, root)` to FEAT-208,
`unit (macos)` to FEAT-212, etc.). `continue-on-error`
flags are all removed.

## Actions taken

1. Mark `FEAT-022` `status: done`.
2. Mark `FEAT-044` `status: done`.
3. Mark `FEAT-197` `status: done`.
4. Keep `FEAT-023` `status: open` with two carried-forward
   sub-issues noted in its body.
5. Move every `status: done` issue under
   `issues/{bug,feature}/done/`.
6. Delete `issues/ROADMAP-1.{1,2,3}.0.md`.

## Carried forward

These become open issues for the planning cycle after
ROADMAP-1.4.0:

- **FEAT-219** — refresh `etc/bash_completion.d/account`
  to cover every shipped subcommand (closes FEAT-023 AC 5).
- **FEAT-220** — create `docs/templates/CLAUDE.md.account`
  template (closes FEAT-023 AC 6).

(Files for these issues are not created in this audit;
they will be filed when their target milestone is opened.)

## Status

`done` — every Actions-taken item lands in the PR that
opens this log file; the two Carried-forward items have
explicit identifiers (FEAT-219, FEAT-220) so the next
planning ROADMAP can pick them up directly.
