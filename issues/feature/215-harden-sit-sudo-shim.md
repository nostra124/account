---
id: FEAT-215
type: feature
priority: low
status: open
---

# Harden SIT runner sudo shim against accidental non-container execution

## Description

**As a** developer who might run `tests/sit/runner.sh` directly on a
workstation
**I want** the sudo shim to refuse to write when outside a container
**So that** `/usr/local/bin/sudo` on the host machine is never
silently overwritten by a test script.

## Current risk

`tests/sit/runner.sh:47-57`:

```sh
if ! command -v sudo >/dev/null 2>&1; then
    [ "$(id -u)" -eq 0 ] || {
        echo "SIT: sudo missing and not root; cannot proceed" >&2
        exit 2
    }
    cat > /usr/local/bin/sudo <<'SUDO'
#!/bin/sh
exec "$@"
SUDO
    chmod +x /usr/local/bin/sudo
fi
```

The only guard is `id -u == 0`. If a developer runs `runner.sh`
directly as root on their workstation (e.g. `sudo sh
tests/sit/runner.sh git`) and the workstation happens to lack
`sudo` on `PATH` at that moment, the shim is installed to
`/usr/local/bin/sudo` on the live system.

`tests/sit/run.sh` does exit 0 with a soft-skip when no container
engine is present, so normal `make check-sit` invocations never
reach `runner.sh` directly. The risk exists only for manual
invocations, but it is worth closing.

## Implementation

Add a container-environment check before the shim is written:

```sh
# Refuse to write the sudo shim unless we are inside a container.
# Containers typically have /.dockerenv (Docker) or are identified
# by cgroup namespacing. Requiring SIT_IN_CONTAINER=1 is the
# simplest explicit guard.
in_container() {
    [ -f /.dockerenv ] || [ "${SIT_IN_CONTAINER:-0}" = "1" ]
}

if ! command -v sudo >/dev/null 2>&1; then
    [ "$(id -u)" -eq 0 ] || {
        echo "SIT: sudo missing and not root; cannot proceed" >&2
        exit 2
    }
    if ! in_container; then
        echo "SIT: refusing to install sudo shim outside a container" \
             "(set SIT_IN_CONTAINER=1 to override)" >&2
        exit 2
    fi
    cat > /usr/local/bin/sudo <<'SUDO'
...
```

`tests/sit/run.sh` should pass `-e SIT_IN_CONTAINER=1` to the
container `run` command so the inner invocation is authorised.

## Acceptance Criteria

1. `runner.sh` refuses to write the sudo shim when `/.dockerenv`
   is absent and `SIT_IN_CONTAINER` is not `1`.
2. `tests/sit/run.sh` passes `-e SIT_IN_CONTAINER=1` to the
   container engine.
3. Existing SIT matrix still passes in container CI.
4. Running `runner.sh` directly as root outside a container (no
   `/.dockerenv`) prints a clear error and exits non-zero.
