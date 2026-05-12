---
id: FEAT-214
type: feature
priority: low
status: done
---

# Pin `slaves` case-insensitivity asymmetry: test or fix the inconsistency

## Description

**As a** contributor reading the `account` source
**I want** the case-folding behaviour of `slaves` to be explicitly
tested and documented (or fixed)
**So that** callers know whether `account slaves Alice@example.com`
and `account slaves alice@example.com` are equivalent.

## Observed asymmetry

`command:has` (`bin/account:725`) lowercases its argument:

```bash
local ACCOUNT=$(echo "$1" | tr [A-Z] [a-z])
```

`command:slaves` (`bin/account:922-930`) does **not** lowercase:

```bash
command:slaves() {
    local ACCOUNT=$1
    if [ -z "$ACCOUNT" ]; then
        local ACCOUNT=$(command:identity)
    fi
    test -f ${SELF_CONFIG}/slaves/$ACCOUNT && cat ${SELF_CONFIG}/slaves/$ACCOUNT
    return 0
}
```

So `account slaves Alice@example.com` looks for a file named
`Alice@example.com` while `account has Alice@example.com` normalises
to `alice@example.com`. A slaves file written under the lowercase
identity would not be found via the mixed-case lookup.

This is either:
1. **A bug** — `slaves` should lowercase like `has`, `insert`, and
   `remove` do; or
2. **Intentional** — the slaves filename is an opaque identifier
   passed verbatim from `command:identity` (which lowercases at
   `hostname -f | tr '[:upper:]' '[:lower:]'`), and callers are
   expected never to use uppercase.

## Implementation

Either path requires a test to pin the behaviour:

**If fixing (lowercase `slaves`):**

```bash
command:slaves() {
    local ACCOUNT=$(echo "${1:-}" | tr [A-Z] [a-z])
    ...
}
```

Add test:

```bats
@test "slaves lowercases account argument" {
    echo "carol@example.com" > "$SELF_CONFIG/slaves/alice@example.com"
    run "$ACCOUNT_BIN" slaves Alice@Example.COM
    [ "$status" -eq 0 ]
    [[ "$output" == *"carol@example.com"* ]]
}
```

**If documenting (leave as-is):**

Add a test that explicitly pins that `slaves Alice@example.com` does
NOT match a file named `alice@example.com`:

```bats
@test "slaves is case-sensitive (unlike has)" {
    echo "carol@example.com" > "$SELF_CONFIG/slaves/alice@example.com"
    run "$ACCOUNT_BIN" slaves Alice@example.com
    [ "$status" -eq 0 ]
    [ -z "$output" ]   # mixed-case finds nothing
}
```

And document the inconsistency in `docs/account.md`.

## Acceptance Criteria

1. A decision is made: fix or document.
2. A test pins the chosen behaviour.
3. If fixing: `bats tests/unit/account.bats` passes including the
   new lowercase test.
4. If documenting: `docs/account.md` notes the case-sensitivity
   difference between `has` and `slaves`.
