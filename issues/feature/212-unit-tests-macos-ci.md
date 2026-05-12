---
id: FEAT-212
type: feature
priority: medium
status: done
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
4. `continue-on-error: true` is removed once the job is green.

## Status — done

Resolved via the CI-failure → PR-comment channel introduced in
the testing-institutions commit (`tests/ci-post-failure.sh`).
The next failing `unit (macos)` run posted its log tail to the
PR, surfacing test 51 (`slaves is case-sensitive (unlike has,
FEAT-214)`) as the sole failure.

Root cause: macOS GitHub runners use APFS in its default
case-insensitive mode. The script's `command:slaves` reads a
file by its argument verbatim; on a case-insensitive
filesystem, `Alice@example.com` and `alice@example.com`
resolve to the same inode, so the script's lack of lowercasing
is unverifiable from runtime behaviour.

Fix: the test now probes filesystem case-sensitivity (creates
a lowercase file, checks whether the uppercase name resolves
to it) and skips cleanly when case-insensitive. The asymmetry
documented in FEAT-214 is still pinned by code review and the
test continues to assert correctness on case-sensitive
filesystems (Linux ext4/xfs).

`continue-on-error: true` has been removed from `unit-macos`.
