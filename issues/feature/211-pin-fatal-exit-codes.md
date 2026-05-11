---
id: FEAT-211
type: feature
priority: low
status: open
---

# Pin `fatal` exit codes in unit tests: distinguish status 1 from 255

## Description

**As a** caller of `account` in a shell pipeline
**I want** the exit codes from error-path subcommands to be stable
and documented
**So that** a future cleanup of `fatal` call sites doesn't silently
change the exit value that downstream `case $?` or `||` handlers
see.

## Background

`fatal()` in `bin/account` defaults the second argument to `1`
(`exit "${2:-1}"`). Many call sites, however, pass `-1` explicitly:

```bash
fatal "Please specify a user name" -1
```

In bash, `exit -1` wraps to 255 (8-bit unsigned truncation).
The current tests check only `[ "$status" -ne 0 ]`, which passes
for both 1 and 255 — any future change from one to the other goes
undetected.

Two distinct caller conventions exist today:

| Pattern | Sites | Resulting status |
|---------|-------|-----------------|
| `fatal "msg"` | has, has-gpg-key, has-ssh-key, remote-url, insert, put, set, get, gpg-import-public-key, gpg-delete-key, ssh-import-public-key | 1 |
| `fatal "msg" -1` | create-user, delete-user, add-user, insert (several), put | 255 |

## Implementation

For each error-path test, change `[ "$status" -ne 0 ]` to the
specific expected code:

```bats
# fatal "msg" → exit 1
@test "has without account argument exits non-zero with fatal" {
    run "$ACCOUNT_BIN" has
    [ "$status" -eq 1 ]
    [[ "$output" == *"please specify an account"* ]]
}

# fatal "msg" -1 → exit 255 (bash truncation of -1)
@test "create-user without name exits fatal" {
    run "$ACCOUNT_BIN" create-user
    [ "$status" -eq 255 ]
    [[ "$output" == *"Please specify a user name"* ]]
}
```

Add a comment in `account.bats` explaining the 255-from-(-1) rule
so future contributors don't mistake it for an error in the test.

Optionally — separate concern — normalise all `-1` call sites to
use `1` in `bin/account` so the two conventions collapse to one.
That is a `bin/account` change and should be weighed carefully (any
caller today checking `$? -eq 255` would break). Document the
decision in the issue resolution either way.

## Acceptance Criteria

1. Every error-path test asserts the exact expected exit status
   (1 or 255), not just non-zero.
2. A code comment in `account.bats` explains the 255 provenance.
3. The decision on normalising `-1` call sites in `bin/account` is
   recorded (even if the decision is "leave as-is").
4. `bats tests/unit/account.bats` passes.
