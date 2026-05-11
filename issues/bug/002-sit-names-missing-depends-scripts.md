---
id: BUG-002
type: bug
priority: high
status: open
---

# SIT default `SIT_NAMES` lists depends scripts that are not shipped

## Severity

**High.** `tests/sit/run.sh` and `.github/workflows/ci.yml` both
reference `bash git gpg openssh stow rpk` as the set of depends
scripts to exercise. The repo ships only `gpg openssh rpk` under
`.rpk/depends/`. `tests/sit/runner.sh` exits with status 2 whenever
the target script is not executable, so the CI matrix fails for
`bash`, `git`, and `stow` on every run — three of the six cells in
`sit-linux` and three of the six in `sit-darwin`.

## Observed

```
SIT: .rpk/depends/bash not executable
SIT: .rpk/depends/git not executable
SIT: .rpk/depends/stow not executable
SIT: 3 / 6 failures
```

(`tests/sit/runner.sh:23` — `[ -x "$SCRIPT" ] || { echo "SIT: $SCRIPT not executable" >&2; exit 2; }`)

## Root Cause

The default `SIT_NAMES` value in `tests/sit/run.sh:39` and the
hardcoded loop in `.github/workflows/ci.yml:52` were written for a
broader collection-wide script set, not trimmed down to what
`account` actually ships. `account`'s only declared runtime
dependencies are `gpg`, `openssh`, and `rpk`; `bash`, `git`, and
`stow` have no `.rpk/depends/` scripts here.

## Fix Plan

Choose one of:

1. **Trim the defaults.** Change the `SIT_NAMES` default in
   `tests/sit/run.sh` from `"bash git gpg openssh stow rpk"` to
   `"gpg openssh rpk"` and update the matching loop in
   `ci.yml` (sit-darwin step).

2. **Add the missing scripts.** Write `.rpk/depends/bash`,
   `.rpk/depends/git`, and `.rpk/depends/stow` if `account`
   genuinely needs those tools at runtime. Auditing `bin/account`
   reveals it calls `bash`, `git`, and `stow` only indirectly
   (git config in `command:init`; stow is the install mechanism,
   not a runtime call). Option 1 is correct.

## Acceptance Criteria

1. `SIT_NAMES` default and the `ci.yml` loop list only the names
   for which `.rpk/depends/<name>` exists.
2. `tests/sit/run.sh` exits 0 on a clean checkout with no
   container engine present (soft-skip path) and exits 0 in a
   container with the trimmed list.
3. GitHub Actions `sit-linux` and `sit-darwin` jobs go green.
