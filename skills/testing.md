---
name: testing
description: |
  Testing institutions for the `account` package — the three
  test layers (unit / SIT / PIT), pre-push hygiene per
  environment (cloud sandbox vs desktop with podman), the
  GitHub Actions matrix, and the "post failure to PR comment"
  mechanism that gives the maintaining agent log-tail access
  to CI failures without needing workflow-log downloads.
---

# `account` — testing institutions

This document is the single source of truth for how `account`
is tested. The same script (`tests/pre-push.sh`) is invoked
from three entry points (git hook, `make pre-push`, CI), so
behaviour is identical across the three.

## 1. Test layers

### Unit — `tests/unit/*.bats`

- Pure-bash subset of `bin/account`. Sandboxed `$HOME` per
  test (rpk pattern), no gpg / ssh / fping / sudo required.
- **Always runs** in any environment that has `bats` on PATH.
- The sandbox is preserved under root via the
  `ACCOUNT_HOME_OVERRIDE=1` envvar (FEAT-208).

### SIT — System Integration Tests — `tests/sit/`

- Drives `.rpk/depends/<name>` install scripts inside fresh
  container images. Verifies the package's runtime
  dependencies install cleanly on every supported distro
  (ubuntu / debian / fedora / arch / alpine) and on Darwin.
- **Requires a functional container engine** (podman or
  docker). The inner runner (`tests/sit/runner.sh`) also
  refuses to install the sudo shim outside a container
  (FEAT-215).

### PIT — Performance Integration Tests — `tests/pit/` (reserved)

- Not used by `account` today. Convention reserved for the
  per-package layout: when present, `tests/pit/run.sh` and
  `tests/pit/*.bats` are picked up by the pre-push runner.

## 2. Pre-push hygiene

Single entrypoint: **`tests/pre-push.sh`**. Run it before
every `git push`. The script self-selects layers:

| Environment | Layers run |
|-------------|-----------|
| Cloud sandbox (no engine, no podman/docker) | unit |
| Desktop with podman or docker reachable | unit + SIT + PIT (if dir exists) |
| `bats` missing | (warn and exit 0; layer unavailable) |
| Engine binary present but daemon down | skip SIT/PIT cleanly (warned) |

Three equivalent entry points:

    sh tests/pre-push.sh           # direct
    make pre-push                  # via Makefile
    git push                       # via .githooks/pre-push, if installed

Install the git hook once per clone:

    make install-hooks
    # equivalent to: git config core.hooksPath .githooks

Agent contract: when working in this repo from any
environment, run `tests/pre-push.sh` (or `make pre-push`)
**before every push**. The script soft-skips layers whose
prerequisites are absent — there is no excuse to skip the
unit layer on a host that has `bats`.

## 3. CI — GitHub Actions matrix

`.github/workflows/ci.yml` runs:

| Job | Runs on | Layer | Blocks merge |
|-----|---------|-------|-------------|
| `lint (typos)` | ubuntu | grep guards (BUG-005, BUG-004) | yes |
| `unit (linux)` | ubuntu, runner user | unit | yes |
| `unit (linux, root)` | ubuntu, sudo | unit (root path) | yes |
| `unit (macos)` | macos | unit | yes (FEAT-212 closed) |
| `sit (<image>)` | ubuntu, docker | SIT per-image | yes |
| `sit (darwin)` | macos | SIT (depends-scripts) | yes |

### Listening for CI completion (no polling)

After pushing, the agent **subscribes** to the PR
(`subscribe_pr_activity`) and **ends its turn**. Both green
and red completion events arrive as
`<github-webhook-activity>` messages — there is no scenario
where the session "hangs waiting for CI" because every
terminal CI status delivers a wake. See
`skills/automerging.md` §5 for the full contract; the
short version is **subscribe + end-turn**, never poll.

## 4. Failure → PR-comment channel

Every job that runs tests tees its output to
`${{ runner.temp }}/<job>.log` and calls
`tests/ci-post-failure.sh` on failure. The script posts a
PR comment containing:

- a stable marker (`<!-- ci-failure: <job> -->`)
- the workflow run URL and short SHA
- the last 200 lines of the captured log

The comment is intended for the maintaining agent: it reads
PR comments via the GitHub MCP server but does **not** have
workflow-log download access. The PR-comment channel is the
contract that closes that gap.

Permissions: `pull-requests: write` is set at the workflow
level (top of `ci.yml`). The `GITHUB_TOKEN` covers
`gh pr comment` without any secrets.

## 5. Local debugging

If a CI job fails and the PR comment shows an assertion you
need to reproduce locally:

    # Run only the failing layer
    bats tests/unit/<failing>.bats        # unit
    tests/sit/run.sh                       # SIT (requires engine)

    # Run as root locally (mirrors `unit (linux, root)` CI job)
    sudo --preserve-env=PATH bats tests/unit/*.bats

    # Run with debug trace
    bats --print-output-on-failure tests/unit/*.bats

## 6. Adding new tests

- **Unit:** add to `tests/unit/account.bats`. Per-file
  `setup()` already sandboxes `$HOME`, `$XDG_*_HOME`, and
  exports `ACCOUNT_HOME_OVERRIDE=1` so EUID==0 doesn't break
  the sandbox.
- **SIT:** add a script under `.rpk/depends/<name>` and a
  case-arm in `tests/sit/runner.sh` if the install probe
  isn't covered by the generic `command -v <name>` check.
- **PIT:** create `tests/pit/run.sh` (or `*.bats`); the
  pre-push runner picks it up automatically.

Every new test must pass in `tests/pre-push.sh` before it
lands on master. The CI matrix is the second line of
defence — `make pre-push` is the first.
