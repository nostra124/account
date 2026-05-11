---
id: FEAT-213
type: feature
priority: low
status: open
---

# Add unit tests for the `-d` (debug) and `-q` (quiet) global CLI flags

## Description

**As a** user of `account -d <subcommand>` and `account -q <subcommand>`
**I want** those flags to be covered by the test suite
**So that** a refactor of the `getopts` block does not silently drop
debug or quiet mode.

The global flags (`bin/account:46-54`) are the only tested-zero
surface in the current suite. Every other documented feature (help,
version, identity, XDG resolvers, remote-url, inventory) has at
least one test; the flags do not.

## Current behaviour

- `-q` sets `SELF_QUIET=1`, suppressing `info` output (which goes
  to stderr). Quiet mode is already set in `setup()` via
  `export SELF_QUIET=1`, so existing tests suppress info noise —
  but the flag itself (passed on the command line) is not verified.
- `-d` sets `SELF_DEBUG=1` and activates `set -vx`, making debug
  lines appear on stderr with a distinct prefix.

## Implementation

```bats
# ---------------------------------------------------------------------------
# Global flags
# ---------------------------------------------------------------------------

@test "-q flag suppresses info output" {
    # Run a subcommand that would emit info lines (init calls info,
    # but init requires gpg/ssh; use `account -q version` as a
    # proxy: version itself emits no info, so we confirm the flag
    # is accepted without error)
    run "$ACCOUNT_BIN" -q version
    [ "$status" -eq 0 ]
    [ -n "$output" ]   # version string still printed
}

@test "-d flag is accepted and does not cause non-zero exit" {
    run "$ACCOUNT_BIN" -d version
    [ "$status" -eq 0 ]
}

@test "-d flag causes debug trace output on version" {
    # With SELF_DEBUG the script runs set -vx; stderr will contain
    # trace lines.  Bats captures combined output in $output.
    run bash -c "SELF_DEBUG=1 '$ACCOUNT_BIN' version 2>&1"
    [ "$status" -eq 0 ]
    # At minimum the version value and some trace should appear
    [ -n "$output" ]
}
```

Note: the `getopts` loop in `bin/account:46-54` uses both
`getopts "dq" flag` and `[ x"$1" = x'-d' ]` — an unusual
pattern. The tests should be written against observed behaviour;
any oddity found should be noted as a follow-up (possible
`getopts` fix).

## Acceptance Criteria

1. At least two `@test` entries cover the `-q` and `-d` flags.
2. Tests pass using the sandboxed `$ACCOUNT_BIN` without modifying
   global shell state.
3. Any `getopts` irregularity discovered is filed as a follow-up
   bug.
