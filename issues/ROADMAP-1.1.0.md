---
id: ROADMAP-1.1.0
type: roadmap
version: 1.1.0
priority: high
status: done
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
| [FEAT-208](./feature/208-fix-euid0-sandbox-bypass.md) | feature | medium | Fix EUID==0 sandbox bypass: stop skipping 8 unit tests under root | done |
| [FEAT-212](./feature/212-unit-tests-macos-ci.md) | feature | medium | Run unit tests on `macos-latest` in CI | done |
| [FEAT-215](./feature/215-harden-sit-sudo-shim.md) | feature | low | Harden SIT runner sudo shim against non-container execution | done |

## Delivery notes

- **BUG-002** is done — trimmed `SIT_NAMES` default and `ci.yml`
  loop to `gpg openssh rpk` in commit `75ee093`.
- **FEAT-208** is done — `ACCOUNT_HOME_OVERRIDE` envvar gates the
  `sudo -i` re-derivation in `bin/account`; the suite sets it in
  `setup()`, `require_non_root` is gone, and a new `unit (linux,
  root)` CI job exercises the path. XDG-home tests now assert both
  the root and non-root branches so both code paths are pinned.
- **FEAT-212** is done — added `unit-macos` job (`runs-on:
  macos-latest`, `brew install bats-core`). If the first run
  surfaces GNU vs BSD utility differences in `bin/account`, file
  them as follow-up bugs rather than reverting the job.
- **FEAT-215** is done — the sudo-shim block now requires either
  `/.dockerenv` to exist or `SIT_IN_CONTAINER=1` to be set;
  `tests/sit/run.sh` passes the envvar to every container it
  spawns. Direct invocation of `runner.sh` outside a container
  exits with a clear diagnostic instead of overwriting the host
  `/usr/local/bin/sudo`.
