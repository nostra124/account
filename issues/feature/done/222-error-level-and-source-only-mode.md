---
id: FEAT-222
type: feature
priority: medium
status: done
---

# Backfill: `error()` log level + `ACCOUNT_SOURCE_ONLY` test mode

## Description

**As a** maintainer reading `bin/account` and discovering
the `error()` helper alongside the existing `fatal`,
`warn`, `info`, `debug` family
**I want** a FEAT that owns this addition so traceability
isn't broken
**So that** the level taxonomy in `skills/logging.md` is
attached to a shipped issue.

Filed as a backfill per **AUDIT-2026-05-13**. The work was
shipped in commit `3870056` (PR #6 squash) without an
owning FEAT.

## What landed

### `bin/account` logger changes

- New `error()` helper — emits `<self>: error - <msg>` in
  red to stderr and returns 1 (non-exiting; callable as
  `error "..." || handle-failure`).
- Format unification: every helper now wraps its
  `<level> - <message>` text in a single ANSI colour span,
  so `<self>: <level> - <message>` survives intact after
  `sed 's/\x1b\[[0-9;]*m//g'`. Before the change, `warn`
  and `info` placed the colour escape *between* the level
  prefix and the message, which broke greppability by
  level when the colour codes were present.
- `return 0` added to `warn` / `info` / `debug` so a
  closed gate doesn't propagate a non-zero status to
  callers.
- `ACCOUNT_SOURCE_ONLY=1` guard near the dispatcher: when
  set, sourcing `bin/account` returns to the caller
  instead of running the help / dispatcher block. Used by
  unit tests to call helpers directly.

### `tests/unit/account.bats` additions

Nine new tests cover the helpers:

- `debug() is silent unless SELF_DEBUG is set`
- `debug() emits 'debug - <msg>' when SELF_DEBUG is set`
- `info() is silent when SELF_QUIET=1`
- `info() emits 'info - <msg>' when SELF_QUIET is unset`
- `warn() emits 'warn - <msg>' to stderr regardless of SELF_QUIET`
- `error() emits 'error - <msg>' and returns 1 (non-exiting)`
- `fatal() emits 'fatal - <msg>' and exits non-zero`
- `fatal() honours explicit second-arg exit code`
- `ACCOUNT_SOURCE_ONLY=1 source returns without running dispatcher`

### `skills/logging.md`

Owned by **FEAT-221** (institution doc), but the level
contract it documents was shaped by this change.

## Acceptance Criteria

Backfilled — these match the artifacts that actually shipped:

1. `error()` is defined in `bin/account` between `fatal()`
   and `warn()`, returns 1, writes to stderr.
2. `warn()`, `info()`, `debug()` all `return 0`
   explicitly.
3. The format `<self>: <ANSI><level> - <msg><reset>` is
   shared by all five helpers (verified by the bats tests
   that match `<level> - <message>` as a contiguous
   substring).
4. `ACCOUNT_SOURCE_ONLY=1` causes `bin/account` to return
   before the dispatcher block.
5. The 9 new bats tests pass; suite count includes them.

## Status

Done at filing time. Backfill record only.
