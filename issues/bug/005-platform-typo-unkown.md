---
id: BUG-005
type: bug
priority: low
status: done
---

# `command:platform` fallback branch outputs literal "unkown"

## Severity

**Low.** Affects only the `*)` wildcard branch of the `uname -s`
case statement — reached on non-Linux, non-Darwin kernels. No
deployed system is expected to hit this path in normal operation,
but any consumer that pattern-matches the platform string
(e.g. `case $(account platform) in ubuntu|debian|macos|…`) will
never match "unkown" or "unknown", and a future typo-fix would
silently change consumer behaviour.

## Observed

`bin/account:1074`:

```bash
*)
    echo "unkown"
    ;;
```

The word is `unkown`, missing the `n` — it should be `unknown`.

## Fix Plan

1. Correct the spelling in `bin/account`:

   ```bash
   *)
       echo "unknown"
       ;;
   ```

2. Add a unit test that pins the output for the fallback path (or
   at minimum documents the corrected spelling in a comment) so
   future regressions are caught.

   Because `uname -s` on the CI runner will always be `Linux` or
   `Darwin`, a direct test of the fallback branch requires either
   a stub or accepting that the spelling is only pinned via code
   review. The simpler guard is a `grep` lint in CI:

   ```sh
   grep -n 'unkown' bin/account && { echo "typo: unkown"; exit 1; } || true
   ```

## Acceptance Criteria

1. `bin/account` outputs `unknown` (correctly spelled) in the
   `*)` fallback of `command:platform`.
2. CI lint (shellcheck or a grep step) catches a recurrence.
3. Existing `platform (no arg) returns a non-empty identifier`
   test still passes; no test previously pinned the misspelling.
