---
id: ROADMAP-1.3.0
type: roadmap
version: 1.3.0
priority: medium
status: done
---

# Release 1.3.0 — Runtime correctness

Fix bugs in `bin/account` itself that affect production behaviour.
These are independent of the test milestones and can be worked
concurrently with ROADMAP-1.2.0, but the test infrastructure from
ROADMAP-1.1.0 should be in place first so each fix can be verified
by the full suite.

Depends on: ROADMAP-1.1.0 (stable CI baseline required first).

## Issues

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [BUG-003](./bug/003-gpg-encrypt-bare-account-call.md) | bug | medium | `gpg-encrypt` calls bare `account list` instead of `command:list` | done |
| [BUG-005](./bug/005-platform-typo-unkown.md) | bug | low | `command:platform` fallback outputs `"unkown"` (spelling typo) | done |
| [BUG-004](./bug/004-version-file-drifts-from-ledger.md) | bug | low | `.rpk/version` drifts from `.rpk/versions` ledger | done |

## Delivery notes

- **BUG-003** done — `$(account list)` replaced with
  `$(command:list)` at `bin/account:474`. Verified no remaining
  bare self-calls via `grep -nE '\$\(account[[:space:]]' bin/account`.
- **BUG-005** done — `unkown` corrected to `unknown` in the
  `command:platform` fallback. A `lint (typos)` CI job greps for
  the misspelling so it cannot regress silently.
- **BUG-004** done — git log of commit `5ff88ff` showed the bump
  to `1.0.2` updated `.rpk/versions` but not `.rpk/version`; the
  latter is now corrected to `1.0.2`. A CI step asserts the two
  files agree on every PR.
