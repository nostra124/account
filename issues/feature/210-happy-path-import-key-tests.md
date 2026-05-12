---
id: FEAT-210
type: feature
priority: medium
status: done
---

# Add happy-path tests for `ssh-import-public-key` and `gpg-import-public-key`

## Description

**As a** contributor verifying the account key-registry write path
**I want** unit tests that confirm a piped key is persisted to
`$SELF_CONFIG/{ssh,gpg}/<key>.pub`
**So that** any regression in the registry-write step is caught
before it reaches production.

Currently the suite tests only the error path (missing key-id
argument). The happy paths for both subcommands are pure filesystem
operations on `$SELF_CONFIG` — fully sandbox-safe — and are
untested.

## Gap

`command:ssh-import-public-key` (`bin/account:608-614`):
1. Reads key from stdin.
2. Writes to `$SELF_CONFIG/ssh/<KEY>.pub`.
3. Appends to `$HOME/.ssh/authorized_keys` and de-dupes.

`command:gpg-import-public-key` (`bin/account:543-548`):
1. Reads key from stdin.
2. Writes to `$SELF_CONFIG/gpg/<KEY>.pub`.
3. Calls `gpg --import` and `gpg --quick-sign-key` — external, but
   both are called *after* the file write; we can assert the file
   write succeeded even if the gpg calls fail gracefully in a
   keyring-less sandbox.

## Implementation

Add to `tests/unit/account.bats`:

```bats
@test "ssh-import-public-key writes key to SELF_CONFIG/ssh/<id>.pub" {
    mkdir -p "$HOME/.ssh"
    echo "ssh-rsa AAAA alice@example.com" \
        | "$ACCOUNT_BIN" ssh-import-public-key alice@example.com
    [ -f "$SELF_CONFIG/ssh/alice@example.com.pub" ]
    grep -q "ssh-rsa AAAA" "$SELF_CONFIG/ssh/alice@example.com.pub"
}

@test "ssh-import-public-key appends to authorized_keys" {
    mkdir -p "$HOME/.ssh"
    echo "ssh-rsa AAAA alice@example.com" \
        | "$ACCOUNT_BIN" ssh-import-public-key alice@example.com
    grep -q "ssh-rsa AAAA" "$HOME/.ssh/authorized_keys"
}
```

For `gpg-import-public-key`, the `gpg --import` / `--quick-sign-key`
calls will fail in a keyring-less sandbox. Stub gpg in the test's
`$PATH` to a no-op, or use `GNUPGHOME` pointed at a temp dir:

```bats
@test "gpg-import-public-key writes key to SELF_CONFIG/gpg/<id>.pub" {
    export GNUPGHOME="$(mktemp -d)"
    echo "-----BEGIN PGP PUBLIC KEY BLOCK-----" \
        | "$ACCOUNT_BIN" gpg-import-public-key alice@example.com || true
    [ -f "$SELF_CONFIG/gpg/alice@example.com.pub" ]
    cleanup: rm -rf "$GNUPGHOME"
}
```

The `|| true` accepts that the subsequent `gpg --import` may fail
on malformed data; the assertion is that the file write happened
regardless.

## Acceptance Criteria

1. At least two new tests cover the `ssh-import-public-key` write
   and `authorized_keys` append paths.
2. At least one new test covers the `gpg-import-public-key` file
   write path.
3. All new tests pass in the sandboxed environment.
4. `bats tests/unit/account.bats` count increases by at least 3.
