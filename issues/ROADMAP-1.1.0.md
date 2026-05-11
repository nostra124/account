---
id: ROADMAP-1.1.0
type: roadmap
version: 1.1.0
priority: high
status: open
---

# Release 1.1.0 — Test infrastructure integrity

Fix the gaps that cause CI to report false results today. These
items must land before any new feature or coverage work, because
until they are resolved SIT results cannot be trusted and 8 unit
tests silently never run.

## Issues

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [BUG-002](./bug/002-sit-names-missing-depends-scripts.md) | bug | high | SIT `SIT_NAMES` lists depends scripts not shipped (`bash git stow`) | done |
| [FEAT-208](./feature/208-fix-euid0-sandbox-bypass.md) | feature | medium | Fix EUID==0 sandbox bypass: stop skipping 8 unit tests under root | open |
| [FEAT-212](./feature/212-unit-tests-macos-ci.md) | feature | medium | Run unit tests on `macos-latest` in CI | open |
| [FEAT-215](./feature/215-harden-sit-sudo-shim.md) | feature | low | Harden SIT runner sudo shim against non-container execution | open |

## Delivery notes

- **BUG-002** is done — trimmed `SIT_NAMES` default and `ci.yml`
  loop to `gpg openssh rpk` in commit `75ee093`.
- **FEAT-208** requires a small hook in `bin/account`
  (`ACCOUNT_HOME_OVERRIDE`) plus removal of `require_non_root` from
  the suite. Low risk; high payoff for container CI.
- **FEAT-212** may surface GNU vs BSD portability issues (e.g.
  `stat -c` vs `stat -f`). File those as follow-ups; do not block
  the release on them.
- **FEAT-215** is a safety net. Land alongside FEAT-208 since both
  touch `tests/sit/`.
