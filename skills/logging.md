---
name: logging
description: |
  Logging contract for the `account` package — five levels
  (debug / info / warn / error / fatal), envvar gates, the
  source-only mode that lets unit tests call helpers directly,
  and the format invariant that keeps output greppable when
  colours are stripped.
---

# `account` — logging contract

Five levels defined in `bin/account`. All write to stderr; none
write to stdout (stdout is reserved for command output that
callers may pipe).

## Levels

| Level | Function | Gate | Exit / return |
|-------|----------|------|---------------|
| debug | `debug "msg"` | `SELF_DEBUG=1` (set by `-d`) | `return 0` |
| info  | `info "msg"`  | `SELF_QUIET` **unset** (silenced by `-q`) | `return 0` |
| warn  | `warn "msg"`  | always emitted | `return 0` |
| error | `error "msg"` | always emitted | `return 1` (non-exiting) |
| fatal | `fatal "msg" [N]` | always emitted | `exit ${2:-1}` |

Severity order (low → high): **debug < info < warn < error < fatal**.

## Choosing the level

- **debug** — diagnostic detail only the developer cares about
  (which branch ran, which file path resolved). Off by default.
- **info** — normal progress narration ("generating new gpg key
  for alice@host"). Suppressible with `-q` so scripts can
  silence chatter.
- **warn** — recoverable surprise the user should know about,
  but the operation continues ("host X not reachable; skipped").
- **error** — operation failed but the surrounding flow can
  continue (one host in a fan-out failed; the others should
  still run). Returns 1 so callers can chain `error "..." ||
  handle`.
- **fatal** — operation cannot continue; the process exits.
  Takes an optional second argument for the exit code.

When in doubt, escalate: warn > info, and error > warn.

## Format invariant

Every level emits exactly:

    <self>: <ANSI-colour><level> - <message><reset>

- `<self>` is `$(basename $0)`, normally `account`.
- `<level>` is the literal word: `debug` / `info` / `warn` /
  `error` / `fatal`.
- The ANSI colour wraps `<level> - <message>` together, so even
  when output is piped through `sed 's/\x1b\[[0-9;]*m//g'` the
  prefix `<self>: <level> - <message>` survives intact.

This is the contract `tests/unit/account.bats` checks for. Any
change to the format must update the tests.

## Envvar gates

| Var | Effect |
|-----|--------|
| `SELF_DEBUG=1` | `debug` is emitted (also activates `set -vx` early in `bin/account`) |
| `SELF_QUIET=1` | `info` is silenced |
| `ACCOUNT_SOURCE_ONLY=1` | `bin/account` returns before the dispatcher runs, so tests can source the file and call helpers directly |

Command-line equivalents: `-d` sets `SELF_DEBUG`, `-q` sets
`SELF_QUIET`. Set globally for sticky behaviour across many
invocations:

    export SELF_QUIET=1   # silence info from every account call

## Unit-test integration

Helpers are tested in `tests/unit/account.bats` by sourcing the
script with `ACCOUNT_SOURCE_ONLY=1`:

    run bash -c "ACCOUNT_SOURCE_ONLY=1 source '$ACCOUNT_BIN'; \
                 SELF_QUIET=1 info 'hello' 2>&1"
    [ "$status" -eq 0 ]
    [ -z "$output" ]   # silenced

Every helper has at least:
- a "silent when gated" test (debug, info)
- an "emits with prefix" test
- a "returns the right exit code" test (return 0 vs return 1 vs exit)

See the "Logging helpers" section near the top of
`tests/unit/account.bats`.

## What logging is *not* for

- **Errors users need to see and act on** — use `error`/`fatal`
  with a clear, action-oriented message. Don't bury those in
  `info` or `warn`.
- **Machine-readable output** — stdout is the data channel.
  Tools that need structured failure data should parse the exit
  code, not the log line.
- **Secrets** — never log GPG / SSH private material. Public
  keys, fingerprints, and account names are fine.
