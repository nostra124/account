---
id: ROADMAP-1.2.0
type: roadmap
version: 1.2.0
priority: medium
status: open
---

# Release 1.2.0 — Unit test coverage gaps

Add the pure-bash unit tests that are missing from the suite. None
of these require external tools (gpg / ssh / fping). The suite's
stated scope (file header in `tests/unit/account.bats`) is "every
pure-bash subcommand whose happy path doesn't require external
calls"; these issues close the gap between that intent and reality.

Depends on: ROADMAP-1.1.0 (stable CI baseline required first).

## Issues

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [FEAT-209](./feature/209-expand-pure-bash-unit-coverage.md) | feature | medium | Expand pure-bash coverage: `domainname`, cached-key exports, `ssh-export-known-host`, multi-`remove`, `master` empty-comment | open |
| [FEAT-210](./feature/210-happy-path-import-key-tests.md) | feature | medium | Happy-path tests for `ssh-import-public-key` and `gpg-import-public-key` | open |
| [FEAT-213](./feature/213-test-global-flags.md) | feature | low | Unit tests for `-d` / `-q` global CLI flags | open |
| [FEAT-211](./feature/211-pin-fatal-exit-codes.md) | feature | low | Pin `fatal` exit codes (distinguish status 1 from 255) | open |
| [FEAT-214](./feature/214-slaves-case-insensitivity-asymmetry.md) | feature | low | Pin `slaves` case-insensitivity asymmetry: test or fix | open |

## Delivery notes

- **FEAT-209** and **FEAT-210** are pure test additions with no
  `bin/account` changes. Good first-contribution material; can be
  worked in parallel.
- **FEAT-211** is best done after deciding whether to normalise
  `fatal "msg" -1` call sites to `fatal "msg" 1` in `bin/account`.
  If the normalisation happens first, all exit codes become 1 and
  the test assertions simplify.
- **FEAT-214** requires a design decision (fix `slaves` to lowercase
  vs document the asymmetry). Review the `slaves` and `has` call
  sites together before writing the test.
