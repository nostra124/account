---
id: FEAT-044
type: feature
priority: low
status: done
---

# `secret` (and `config`) lean on `account` for SSH-remote resolution

## Description

**As a** maintainer
**I want** secret's (and config's, where applicable) git-backed
synchronisation to ask `account` for the canonical SSH endpoint
of an account, not hard-code its own format
**So that** the SSH-endpoint format lives in exactly one place
(`account`) and a future change there propagates through every
consumer without each script needing its own update.

Today `bin/secret`'s `command:pull` resolves remotes as
`${ACCOUNT}:~/.password-store` (or similar) — a literal SSH
host:path string assembled inside secret. Now that secret
declares `account` as a hard runtime dep (FEAT-029, FEAT-031),
the natural move is to delegate the resolution.

This is a small "smaller optimisation" rather than a large rework
— specifically called out as such in earlier discussion.

## Implementation

1. **Define `account remote-url <account-name> [<purpose>]`** as
   the contract. `<purpose>` is an optional namespace (e.g.
   `password-store`, `cluster-config`, `bitcoin-wallet/<name>`)
   so different consumers can request different paths under the
   same account. The output is a single SSH URL (e.g.
   `alice:~/.password-store` or `alice:~/.config/cluster/`).
2. **Replace** the inlined endpoint construction in
   `bin/secret`'s `command:pull` / `command:push` /
   `command:sync` with calls to `account remote-url ...`.
3. **Apply** the same replacement to `bin/config` if/where it has
   parallel logic. Audit at implementation time.
4. Update `tests/unit/{secret,config}.bats` to mock
   `account remote-url` and assert the calls happen with the
   right arguments.

This ticket also reinforces FEAT-043's harmonisation goal — once
all sync flows go through the same endpoint resolver, their
behaviour aligns naturally.

## Acceptance Criteria

1. `account remote-url <name> [<purpose>]` exists and returns
   a canonical SSH URL, documented in `docs/account.md` and
   `account(1)`.
2. `bin/secret` no longer constructs SSH host:path strings
   inline; every endpoint comes from `account remote-url`.
3. `bin/config` — same, where the equivalent logic exists.
4. Tests assert the new dispatch path.
5. End-to-end: `secret push` against a known-configured account
   succeeds against the same target it did before, with no
   user-visible behaviour change.
