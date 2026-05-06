---
id: BUG-001
type: bug
priority: high
status: done
---

# `bin/account`: `fatal "msg"` without status arg silently exits 0

## Severity

**High.** Subcommands intended to abort on bad input return exit
code 0 instead, so callers (other scripts, CI guards, shell `&&`
pipelines) treat the failure as success. The fatal *message* is
printed to stderr, but `$?` is `0`, defeating any
`account ... || handle-failure` pattern.

## Observed

The helper at `bin/account` lines 13–16 is:

    fatal() {
        echo -e "$SELF: \033[31;mfatal - $1\033[0m" >&2
        exit $2
    }

Several call sites pass only the message and omit the second
(exit-status) argument:

| Line | Subcommand                  | Call                                         |
|------|-----------------------------|----------------------------------------------|
|  540 | `gpg-import-public-key`     | `fatal "please specify a key id"`            |
|  559 | `gpg-delete-key`            | `fatal "please specify a key id"`            |
|  605 | `ssh-import-public-key`     | `fatal "please specify a key id"`            |
|  638 | `insert`                    | `fatal "no local git user mail configured"`  |
|  639 | `insert`                    | `fatal "no local git user name configured"`  |
|  695 | `insert`                    | `fatal "ssh-copy-id $ACCOUNT - failed"`      |
|  719 | `has`                       | `fatal "please specify an account"`          |
|  728 | `has-gpg-key`               | `fatal "please specify an account"`          |
|  736 | `has-ssh-key`               | `fatal "please specify an account"`          |
| 1117 | `put`                       | `fatal "please specify a file name"`         |
| 1118 | `put`                       | `fatal "file $1 does not exist"`             |
| 1135 | `put`                       | `fatal "host $ACCOUNT_HOST not reachable"`   |
| 1142 | `set`                       | `fatal "please specify an file name"`        |
| 1164 | `get`                       | `fatal "please specify an file name"`        |
| 1199 | unknown-command dispatcher  | `fatal "unknown command $1 ${@:2}"`          |

With `$2` unset, `exit ` (no argument) returns the previous
command's status. The previous command is the stderr `echo` from
`fatal`, which exits 0. Therefore the script terminates with 0.

Consequence at line 1199: the trailing `command:help` and
`exit -1` after `fatal` are unreachable.

## Root Cause

Inconsistent caller convention for the `fatal` helper. Some sites
pass an explicit `-1` (e.g. `bin/account:411`,
`fatal "please specify a user name" -1`); others omit it. The
helper does not default `$2` when missing.

## Fix Plan

Two equivalent fixes; pick one and apply consistently.

1. **Default the helper.** Change `fatal` to default the status
   when omitted:

        fatal() {
            echo -e "$SELF: \033[31;mfatal - $1\033[0m" >&2
            exit "${2:-1}"
        }

   This is one line and fixes every caller in place. Recommended.

2. **Audit every call site.** Add the explicit `-1` to each line
   listed above. Same outcome; more churn.

After the fix, line 1199's `command:help` after `fatal` becomes
unreachable in a different way (the `exit` always fires) — drop
the `command:help` and the trailing `exit -1` to keep the
dispatcher honest.

## Regression Protection

`tests/unit/account.bats` already contains tests that document
the intended behaviour for each of these subcommands; they are
gated with `skip "BUG-001: ..."` today. Removing the `skip` line
in each test re-arms the regression guard.

A smoke check that catches *future* regressions of the same
shape:

    @test "all error-path subcommands exit non-zero when called bare" {
        for cmd in gpg-import-public-key gpg-delete-key \
                   ssh-import-public-key has has-gpg-key has-ssh-key \
                   put set get; do
            run "$ACCOUNT_BIN" "$cmd"
            [ "$status" -ne 0 ] || fail "$cmd: expected non-zero, got $status"
        done
    }

## Acceptance Criteria

1. Every `fatal "msg"` call site in `bin/account` causes the
   script to exit non-zero (verified by removing the `skip`
   lines in `tests/unit/account.bats` and observing they pass).
2. The unknown-command dispatcher exits non-zero with a clear
   message; the dead `command:help` / `exit -1` after `fatal`
   are removed.
3. `bats tests/unit/account.bats` passes with no `skip
   "BUG-001"` lines remaining.
