---
id: ROADMAP-1.2.0
type: roadmap
version: 1.2.0
priority: medium
status: done
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
| [FEAT-209](./feature/209-expand-pure-bash-unit-coverage.md) | feature | medium | Expand pure-bash coverage: `domainname`, cached-key exports, `ssh-export-known-host`, multi-`remove`, `master` empty-comment | done |
| [FEAT-210](./feature/210-happy-path-import-key-tests.md) | feature | medium | Happy-path tests for `ssh-import-public-key` and `gpg-import-public-key` | done |
| [FEAT-213](./feature/213-test-global-flags.md) | feature | low | Unit tests for `-d` / `-q` global CLI flags | done |
| [FEAT-211](./feature/211-pin-fatal-exit-codes.md) | feature | low | Pin `fatal` exit codes (distinguish status 1 from 255) | done |
| [FEAT-214](./feature/214-slaves-case-insensitivity-asymmetry.md) | feature | low | Pin `slaves` case-insensitivity asymmetry: test or fix | done |

## Delivery notes

- **FEAT-209** done — added 7 new tests covering `domainname`,
  `ssh-export-public-key <key>` and `gpg-export-public-key <key>`
  cached paths, `ssh-export-known-host` no-arg fallback,
  `remove` multi-arg, and the `master` no-comment edge case.
- **FEAT-210** done — added 3 import-key happy-path tests
  (`ssh-import-public-key` writes to `$SELF_CONFIG/ssh/` and
  appends to `authorized_keys`; `gpg-import-public-key` writes
  the registry file even when downstream `gpg --import` fails).
- **FEAT-213** done — added 2 global-flag tests (`-q version` and
  `-d version`); the `-d` test asserts the version string appears
  in the trace output.
- **FEAT-211** done — every error-path test now asserts the exact
  expected status (1 for `fatal "msg"`, 255 for `fatal "msg" -1`).
  A header comment in the error-paths section documents the
  255-from-(-1) bash truncation rule. Decision recorded: leave the
  `-1` call sites as-is for now; consumers compare against
  `$? -ne 0`, so the 255 vs 1 distinction is documented but not
  reshaped.
- **FEAT-214** done — decision recorded: document the asymmetry,
  don't fix. `slaves` filenames are opaque identifiers passed
  verbatim from `command:identity`, which already lowercases.
  Test asserts that mixed-case `slaves` argument returns empty.
