---
id: BUG-004
type: bug
priority: low
status: open
---

# `.rpk/version` drifts from `.rpk/versions` ledger

## Severity

**Low.** No runtime behaviour is broken today, but the invariant
documented in CLAUDE.md §8 ("every release is recorded in
`.rpk/versions`; no orphan SHAs") is violated, and `make package`
would stamp a new release on top of an inconsistent baseline.

## Observed

```
$ cat .rpk/version
1.0.1
$ tail -1 .rpk/versions
1.0.2    0a1e819d110fa82c9a1a1a683c1734d30dbb4d65
```

`.rpk/version` reports `1.0.1`; the ledger's latest entry is
`1.0.2`. The binary at runtime reads `.rpk/version` (or the
installed `share/account/version`) and therefore advertises `1.0.1`
while the ledger says the current release is `1.0.2`.

## Root Cause

Either:
- `.rpk/version` was reverted after `1.0.2` was tagged (e.g. a
  forced checkout or cherry-pick), or
- a `make package VERSION=1.0.2` wrote the ledger entry but the
  subsequent `git checkout "$BRANCH" --force` in `.rpk/package`
  reset `.rpk/version` to the branch head, which was still `1.0.1`.

## Fix Plan

1. Determine whether `1.0.2` is the intended current version:
   - If yes: update `.rpk/version` to `1.0.2`.
   - If no (the ledger entry was premature): remove the `1.0.2`
     line from `.rpk/versions` and treat `1.0.1` as current.

2. Add a CI lint step that asserts `cat .rpk/version` matches
   `tail -1 .rpk/versions | awk '{print $1}'`:

   ```sh
   VERSION=$(cat .rpk/version)
   LEDGER=$(tail -1 .rpk/versions | awk '{print $1}')
   [ "$VERSION" = "$LEDGER" ] || {
     echo "version file ($VERSION) != ledger head ($LEDGER)"; exit 1; }
   ```

## Acceptance Criteria

1. `cat .rpk/version` equals the first field of the last line of
   `.rpk/versions`.
2. CI lint step prevents the drift from recurring.
