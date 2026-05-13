---
id: FEAT-219
type: feature
priority: medium
status: done
---

# Refresh `etc/bash_completion.d/account` to cover every shipped subcommand

## Description

**As a** user typing `account <TAB>` at the shell
**I want** every subcommand the binary actually exposes to
appear as a completion candidate
**So that** discovery of the CLI works as expected and
stale completions don't suggest commands that no longer
exist.

The current completion list is from an earlier version of
`bin/account` and includes verbs that have been removed
(`login`, `exec`, `tasks`, `do`) while missing roughly
forty real subcommands. Carried forward from
AUDIT-2026-05-12 as one of the two remaining ACs of
FEAT-023.

## Implementation

1. **Write the failing test first** in
   `tests/unit/account.bats`:

       @test "FEAT-219: every command:<verb> in bin/account is in completion list" {
           completion="$BATS_TEST_DIRNAME/../../etc/bash_completion.d/account"
           local commands=$(awk -F'"' '/local commands=/ {print $2}' "$completion")
           local missing=""
           while IFS= read -r cmd; do
               case " $commands " in
                   *" $cmd "*) ;;
                   *) missing="$missing $cmd" ;;
               esac
           done < <(grep -oE '^command:[a-zA-Z0-9_-]+' "$ACCOUNT_BIN" | sed 's/^command://')
           [ -z "$missing" ] || { echo "missing:$missing" >&2; false; }
       }

   This MUST fail against the current completion file
   (the file is missing ~40 commands).

2. Rewrite the `local commands="..."` line in
   `etc/bash_completion.d/account` to enumerate every
   `command:<verb>` in `bin/account`, sorted alphabetically.
3. Remove the stale `login`, `exec`, `tasks`, `do`
   case-arms (the underlying commands no longer exist).
4. Add contextual `case` arms for the high-value
   account-arg subcommands that didn't have them before:
   `has`, `has-gpg-key`, `has-ssh-key`, `remove`,
   `slaves`, `online`, `insert`, `gpg-fingerprint`,
   `gpg-delete-key`, `gpg-import-public-key`,
   `ssh-import-public-key`.

## Acceptance Criteria

1. The new bats test passes.
2. `etc/bash_completion.d/account`'s `$commands` list is
   in alphabetical order and equals the
   `grep -oE '^command:[a-zA-Z0-9_-]+' bin/account | sed
   's/^command://' | sort -u` output.
3. No stale verbs (`login`, `exec`, `tasks`, `do`) remain
   in the completion file.
4. `bats tests/unit/account.bats` reports 84/84 passing
   (1 new test added).
