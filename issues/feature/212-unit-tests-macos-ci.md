---
id: FEAT-212
type: feature
priority: medium
status: open
---

# Run unit tests on `macos-latest` in CI

## Description

**As a** maintainer shipping `account` for macOS users
**I want** the unit test suite to run on `macos-latest` in GitHub
Actions
**So that** macOS-specific divergences (different `hostname -f`,
`hostname -s`, `hostname -d` output; `stat` flag differences;
bash version differences) are caught before release.

Currently `.github/workflows/ci.yml` runs the unit job only on
`ubuntu-latest`. The `macos-latest` job runs only SIT
(depends-script installation), which doesn't exercise the `bin/account`
subcommands at all.

`bin/account` has multiple `case $(command:platform) in ubuntu|debian|alpine|macos)` branches. The `macos` branch in `command:create-user`,
`command:delete-user`, and `command:add-user` uses macOS-only tools
(`dseditgroup`, `sysadminctl`). While those commands require sudo and
are in the SIT domain, the platform-detection path itself is pure
bash and should be verified under a Darwin kernel.

## Implementation

Add a `unit-macos` job to `.github/workflows/ci.yml`:

```yaml
unit-macos:
  name: unit (macos)
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    - name: Install bats
      run: brew install bats-core
    - name: Run unit tests
      run: bats tests/unit/*.bats
```

If any tests fail only on macOS, they should be fixed (or tagged
with a platform-specific skip) rather than the job being removed.

Known portability hazard: `stat -c '%a'` (GNU) vs
`stat -f '%A'` (BSD/macOS) in `command:put` (`bin/account:1138`).
That subcommand's error-path tests exist; its happy path uses
fping/ssh so it is SIT territory. Flag any other GNU-ism found
during the macOS run.

## Acceptance Criteria

1. `.github/workflows/ci.yml` has a `unit-macos` job that runs
   `bats tests/unit/*.bats` on `macos-latest`.
2. All existing unit tests pass on macOS (or platform-skip with
   a documented reason if genuinely untestable).
3. Any GNU-only utilities found during the macOS run are flagged
   as follow-up issues.
