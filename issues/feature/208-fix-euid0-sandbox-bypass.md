---
id: FEAT-208
type: feature
priority: medium
status: done
---

# Fix EUID==0 sandbox bypass: stop skipping 8 unit tests under root

## Description

**As a** CI maintainer running tests inside a container (which often
executes as root)
**I want** the sandboxed-HOME unit tests to run regardless of EUID
**So that** 8 currently-skipped tests provide real coverage in
container-based CI and no identity-related code path gets a free pass.

Currently `bin/account:66-69` re-derives `HOME` via
`sudo -i sh -c 'echo $HOME'` whenever `EUID == 0`, escaping the
per-test `$HOME` sandbox. The suite defensively `skip`s any test
that reads or writes to the sandboxed HOME under root. This is safe
on a developer laptop, but in a Docker container (which runs as
root by default) those 8 tests never execute.

The 8 affected tests are: `home (no arg)`, `cache-home (no arg)`,
`config-home (no arg)`, `data-home (no arg)`, `share-home (no arg)`,
`source-home (no arg)`, `backup-home (no arg)`, and
`master returns key-comment from authorized_keys`.

## Implementation

Add a single override hook to `bin/account` that the test harness
can use to short-circuit the `sudo -i` re-derivation:

```bash
# bin/account — replace the EUID==0 HOME block:
if [ "$EUID" -eq 0 ] && [ -z "$ACCOUNT_HOME_OVERRIDE" ]; then
    USER=root
    HOME=$(sudo -i sh -c 'echo $HOME')
fi
```

In `tests/unit/account.bats`'s `setup()` function, export the
variable unconditionally (it is a no-op for non-root runs):

```bash
export ACCOUNT_HOME_OVERRIDE=1
```

Remove the `require_non_root` guard from all 8 affected tests (the
function can be deleted entirely if no other skip sites remain).

No functional change for non-root invocations; no behaviour change
for real root invocations that do not set the envvar.

## Acceptance Criteria

1. `ACCOUNT_HOME_OVERRIDE=1` prevents the `sudo -i` HOME
   re-derivation in `bin/account`.
2. All 8 previously-skipped tests execute and pass when the suite
   is run as root (e.g. inside a Docker container).
3. A new CI job or matrix entry (`runs-on: ubuntu-latest`, step
   `sudo bats tests/unit/account.bats`) confirms root-clean.
4. `require_non_root` is removed from the suite.
5. No existing tests regress.
