---
id: FEAT-209
type: feature
priority: medium
status: done
---

# Expand pure-bash unit coverage: missing subcommands and edge cases

## Description

**As a** contributor maintaining the `account` CLI contract
**I want** every pure-bash subcommand and its key edge cases covered
by unit tests
**So that** any signature or behaviour change is caught immediately
without requiring a container or external tools.

Several subcommands that need neither gpg, ssh, fping, nor sudo are
currently untested. The suite's stated scope (file header) is "every
pure-bash subcommand whose happy path doesn't require external
calls" — these gaps contradict that scope.

## Missing tests

### `domainname`

`command:domainname` (`bin/account:336-338`) calls `hostname -d` and
lowercases. Same shape as the existing `nodename` test; trivially
addable.

### `ssh-export-public-key <key>` — cached-file path

`bin/account:598-599`: when `$SELF_CONFIG/ssh/<key>.pub` exists,
`ssh-export-public-key <key>` cats it without any SSH call. This
path is fully sandbox-safe.

```bats
@test "ssh-export-public-key <key> returns cached key file" {
    echo "ssh-rsa AAAA test" > "$SELF_CONFIG/ssh/alice@example.com.pub"
    run "$ACCOUNT_BIN" ssh-export-public-key alice@example.com
    [ "$status" -eq 0 ]
    [ "$output" = "ssh-rsa AAAA test" ]
}
```

### `gpg-export-public-key <key>` — cached-file path

`bin/account:511-512`: same pattern under `$SELF_CONFIG/gpg/`.

### `ssh-export-known-host` — no host key present

`bin/account:620-625`: when `/etc/ssh/ssh_host_rsa_key.pub` does
not exist, the function outputs an empty line. Worth pinning so
callers know the contract.

### `remove` with multiple accounts

`command:remove` iterates `for ACCOUNT in $@` (`bin/account:709`).
Only the single-argument form is tested; test two accounts at once.

### `master` — empty-comment edge case

The `sed 's/.* //g'` in `command:master` strips everything up to
the last space, leaving only the comment field. If a key line has no
trailing comment, the entire line collapses. Pin with a test.

## Implementation

Add the tests above to `tests/unit/account.bats` in the appropriate
sections:

- `domainname` → Identity primitives section
- `ssh/gpg-export-*-key <key>` cached paths → new "Cached key
  export" section between inventory and slaves blocks
- `ssh-export-known-host` no-arg no-key path → after the
  `platform` section
- `remove` multi-arg → existing inventory section
- `master` empty-comment → existing slaves/master section

No changes to `bin/account` required.

## Acceptance Criteria

1. Six or more new `@test` entries cover the gaps listed above.
2. All new tests pass without any external tools.
3. `bats tests/unit/account.bats` reports no failures and the
   count increases by at least 6.
