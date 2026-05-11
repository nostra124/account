---
id: ROADMAP-1.3.0
type: roadmap
version: 1.3.0
priority: medium
status: open
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
| [BUG-003](./bug/003-gpg-encrypt-bare-account-call.md) | bug | medium | `gpg-encrypt` calls bare `account list` instead of `command:list` | open |
| [BUG-005](./bug/005-platform-typo-unkown.md) | bug | low | `command:platform` fallback outputs `"unkown"` (spelling typo) | open |
| [BUG-004](./bug/004-version-file-drifts-from-ledger.md) | bug | low | `.rpk/version` drifts from `.rpk/versions` ledger | open |

## Delivery notes

- **BUG-003** is a one-token substitution (`$(account list)` →
  `$(command:list)`). Verify no other bare self-calls remain with:
  `grep -n '\baccount\b' bin/account | grep -v '^#' | grep -v ACCOUNT`
- **BUG-005** is a one-word spelling fix. Pair it with a `grep`
  lint step in CI so it cannot regress silently.
- **BUG-004** requires a human decision before touching files: is
  `1.0.2` the intended current version, or was the ledger entry
  premature? Inspect the git log around commit `5ff88ff` to decide,
  then either update `.rpk/version` to `1.0.2` or trim the ledger
  entry.
