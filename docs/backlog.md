# `account` — backlog roadmap

> Sorted by theme and priority. Bugs before features at the same
> priority level (per issue authoring convention, CLAUDE.md §3).
> Status key: `open` / `done`.

---

## Milestone 1 — Test infrastructure integrity

These items must land before new feature work: two of them cause
CI to report false-greens today.

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [BUG-002](../issues/bug/002-sit-names-missing-depends-scripts.md) | bug | high | SIT default `SIT_NAMES` lists depends scripts not shipped (`bash git stow`) | open |
| [FEAT-208](../issues/feature/208-fix-euid0-sandbox-bypass.md) | feature | medium | Fix EUID==0 sandbox bypass: stop skipping 8 unit tests under root | open |
| [FEAT-212](../issues/feature/212-unit-tests-macos-ci.md) | feature | medium | Run unit tests on `macos-latest` in CI | open |
| [FEAT-215](../issues/feature/215-harden-sit-sudo-shim.md) | feature | low | Harden SIT runner sudo shim against non-container execution | open |

### Delivery notes

- **BUG-002** is a one-line fix (`SIT_NAMES` default + `ci.yml`
  loop). Do it first; it unblocks reading SIT results honestly.
- **FEAT-208** requires a small hook in `bin/account`
  (`ACCOUNT_HOME_OVERRIDE`) plus removal of `require_non_root` from
  the suite. Low risk; high payoff for container CI.
- **FEAT-212** may surface GNU vs BSD portability issues in
  `bin/account` (e.g. `stat -c` vs `stat -f`). File those as
  follow-ups; do not block the milestone on them.
- **FEAT-215** is a safety net with no urgency. Land it alongside
  BUG-002 since both touch `tests/sit/`.

---

## Milestone 2 — Unit test coverage gaps

Pure-bash paths that belong in unit tests but are absent today.
None of these require external tools (gpg/ssh/fping).

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [FEAT-209](../issues/feature/209-expand-pure-bash-unit-coverage.md) | feature | medium | Expand pure-bash unit coverage: `domainname`, cached-key exports, `ssh-export-known-host`, multi-`remove`, `master` empty-comment | open |
| [FEAT-210](../issues/feature/210-happy-path-import-key-tests.md) | feature | medium | Happy-path tests for `ssh-import-public-key` and `gpg-import-public-key` | open |
| [FEAT-213](../issues/feature/213-test-global-flags.md) | feature | low | Add unit tests for `-d` / `-q` global CLI flags | open |
| [FEAT-211](../issues/feature/211-pin-fatal-exit-codes.md) | feature | low | Pin `fatal` exit codes in unit tests (distinguish status 1 from 255) | open |
| [FEAT-214](../issues/feature/214-slaves-case-insensitivity-asymmetry.md) | feature | low | Pin `slaves` case-insensitivity asymmetry: test or fix | open |

### Delivery notes

- **FEAT-209** and **FEAT-210** are pure test additions with no
  `bin/account` changes. Good first-contribution material.
- **FEAT-211** is best done *after* deciding whether to normalise
  `fatal "msg" -1` to `fatal "msg" 1` in `bin/account`. If the
  normalisation happens, exit codes all become 1 and the tests
  simplify.
- **FEAT-214** requires a design decision (fix vs document). Review
  the `slaves` + `has` call sites together before writing the test.

---

## Milestone 3 — Runtime correctness

Bugs in `bin/account` itself that affect production behaviour.

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [BUG-003](../issues/bug/003-gpg-encrypt-bare-account-call.md) | bug | medium | `gpg-encrypt` calls bare `account list` instead of `command:list` | open |
| [BUG-005](../issues/bug/005-platform-typo-unkown.md) | bug | low | `command:platform` fallback outputs `"unkown"` (spelling typo) | open |
| [BUG-004](../issues/bug/004-version-file-drifts-from-ledger.md) | bug | low | `.rpk/version` drifts from `.rpk/versions` ledger | open |

### Delivery notes

- **BUG-003** is a one-character substitution (`account list` →
  `command:list`). Verify with
  `grep -n '\baccount\b' bin/account | grep -v '^#' | grep -v ACCOUNT`
  that no other bare self-calls exist.
- **BUG-005** is a one-word typo. Pair it with a `grep` lint step
  in CI so it cannot regress.
- **BUG-004** requires a human decision: is `1.0.2` the intended
  current version, or was the ledger entry premature? Resolve by
  inspection of the git log, then either bump `.rpk/version` or
  trim the ledger.

---

## Later / out-of-scope for this backlog

Items already tracked as open features that this review did not
create (pre-existing backlog):

| ID | Title |
|----|-------|
| [FEAT-022](../issues/feature/022-account-becomes-foundation.md) | Make `account` the foundation: flip cycles, no runtime deps |
| [FEAT-023](../issues/feature/023-account-self-contained-package.md) | Account self-contained packaging: docs, tests, man page, completion |
| [FEAT-044](../issues/feature/044-account-remote-url-delegation.md) | `secret`/`config` lean on `account` for SSH-remote resolution |
| [FEAT-197](../issues/feature/197-account-user-agent-skill.md) | `account-user` agent skill |

---

*Last updated: 2026-05-11. Issues created from the test-case review
on branch `claude/review-test-cases-RLuZf`.*
