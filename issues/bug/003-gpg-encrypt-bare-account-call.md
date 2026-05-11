---
id: BUG-003
type: bug
priority: medium
status: open
---

# `gpg-encrypt` calls bare `account list` instead of `command:list`

## Severity

**Medium.** The bug is latent in the no-argument path of
`gpg-encrypt`, which is also the default path callers use.

## Observed

`bin/account:474`:

```bash
for ACCOUNT in $(account list); do
```

This calls whichever `account` binary is first on `$PATH` — not
the current invocation. In a development tree where the installed
`account` has an older key registry, or on a machine where no
`account` is installed at all, the inner `account list` either
returns stale data or fails silently (producing an empty recipient
list), causing `gpg --encrypt` to run with zero recipients and
produce unreadable ciphertext.

Every other internal call in the script uses `command:<verb>`,
e.g. `command:list`, `command:online`, `command:slaves`. The bare
`account` call on line 474 is the only deviation.

## Root Cause

Copy-paste or oversight during `command:gpg-encrypt`'s
implementation. The `account` binary has a self-call pattern
(`$(account list)`) that was correct when `account` was not yet
self-contained but became wrong after FEAT-022 flattened the
invocation model.

## Fix Plan

Change `bin/account:474`:

```bash
# before
for ACCOUNT in $(account list); do
# after
for ACCOUNT in $(command:list); do
```

Verify no other bare `account` self-calls exist:

```
grep -n '\baccount\b' bin/account | grep -v '^#' | grep -v 'ACCOUNT'
```

## Acceptance Criteria

1. `bin/account` contains no bare `account` self-calls;
   `command:list` (or equivalent inline form) is used.
2. A new unit test covers the zero-arg path of `gpg-encrypt`
   when the key registry is empty: it should either produce
   output (empty-recipient case) or exit non-zero with a
   diagnostic, not silently succeed with stale data.
3. `bats tests/unit/account.bats` passes.
