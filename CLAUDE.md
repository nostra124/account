# `account` — developer notes

> The `CLAUDE.md` shipped with the extracted
> `nostra124/account` repo. Mirrors the eight-section
> structure in `docs/templates/CLAUDE.md.foundation`,
> specialised for `account`.

## 1. Scope

`account` is the identity foundation. Its scope is:

- the current Unix user's GPG / SSH keys, git config,
  sudoers
- the set of remote accounts registered with this host
  (each represented by a `<account>.pub` key under
  `$XDG_CONFIG_HOME/account/{ssh,gpg}/`)
- read-only queries of the local platform (FQDN, host
  parts, online status)

Out of scope: configuration storage (that's `config`),
secret material (that's `secret`), repo orchestration
(that's `repo`), system-user provisioning (that's
`user`).

## 2. Repo conventions

Standard rpk per-package conventions: `bin/account`
dispatcher with `command:<verb>` functions, no plugin
loader. Subcommands are inline; there is no
`libexec/account/` because account's surface is small
enough that one self-contained dispatcher beats split
files.

(If a future verb gains real complexity, fold it into
`libexec/account/<verb>` per FEAT-001 — the dispatcher
already handles the libexec lookup pattern.)

## 3. Issue authoring

See **`skills/features.md`** (feature workflow, user-story
template, ROADMAP grouping) and **`skills/bugs.md`** (bug
workflow with strict test-first / TDD discipline) for the
detailed contracts. Summary: frontmatter with `id: FEAT-NNN`
or `id: BUG-NNN`; **bugs come before features at the same
priority level**; every new test lands in the same commit as
the change it covers; CI failures get a PR-comment via
`tests/ci-post-failure.sh` so the responsible agent can read
the assertion that broke.

## 4. The no-shared-lib policy

`account` is the foundation. Every line of code it
needs is right here \(em no calls to other scripts in
the collection at runtime. The only declared dependency
is `rpk` for deployment metadata, never invoked at
runtime.

This means: if `account` needs cache-dir logic,
config-file parsing, or platform detection, it
**inlines** that code. Future contributors will be
tempted to "DRY it up" by reaching for `cache` /
`config` / `data` \(em **don't.** That direction
re-introduces the foundation-breaking cycles FEAT-022
removed.

## 5. What is intentionally duplicated

- **cache-home / config-home / data-home computation.**
  Same shape as the corresponding `cache` / `config` /
  `data` functions, inlined here. Sync semantics are
  weak: bug-fixes propagate by re-implementation, not
  by importing.
- **Platform detection** (`account platform`,
  `account fqdn`). Same logic as `cluster node platform`;
  intentionally duplicated.
- **GPG / SSH key handling.** Direct calls to `gpg(1)`
  and `ssh-keygen(1)`; never delegated to `secret` or
  `crypt`.

## 6. Consumers

Every other script in the collection: `config`, `data`,
`secret`, `crypt`, `repo`, `event`, `services`, `check`,
`user`, `cluster`, `bitcoin`, `lightning`, `dht`, …
each declares `.rpk/depends/account` and calls
`account` for identity / endpoint / GPG-encrypt /
SSH-exec needs.

## 7. Build / install

`./configure && make install` (autoconf umbrella per
FEAT-191). Stow-based install. `master` is always
installable; releases are tagged via `.rpk/version`.

## 8. Versioning

Semver. Every release is recorded in `.rpk/versions`
(TSV ledger \(em no orphan SHAs per rpk's BUG-001
lesson). The `version` builtin returns the current
`.rpk/version`.

## 9. Testing institutions

See **`skills/testing.md`** for the full contract. Summary:

- Three layers: unit (`tests/unit/*.bats`), SIT
  (`tests/sit/`), PIT (`tests/pit/`, reserved).
- One pre-push entry: `tests/pre-push.sh` (also
  `make pre-push`, also `.githooks/pre-push` after
  `make install-hooks`).
- Layer selection by environment:
  - cloud sandbox / no container engine \(em unit only
  - desktop with reachable podman or docker \(em unit + SIT
    (+ PIT if `tests/pit/` exists)
- CI posts every failing job's log tail to the PR as a
  comment (`tests/ci-post-failure.sh`) so the maintaining
  agent has access to failure context without
  workflow-log downloads.

**Agent contract**: run `tests/pre-push.sh` (or
`make pre-push`) before every `git push`. The script
soft-skips layers whose prerequisites are absent, but a
present prerequisite's failure must never be ignored.

## 10. Logging

See **`skills/logging.md`** for the level contract.
Summary: five levels in increasing severity
(debug → info → warn → error → fatal), each writes
to stderr in the format `<self>: <level> - <msg>`
(colour-wrapped). `debug` gated by `SELF_DEBUG`, `info`
silenced by `SELF_QUIET`. `error` is the non-exiting
counterpart to `fatal` and always returns 1. Helpers are
unit-tested via the `ACCOUNT_SOURCE_ONLY=1` source-only
mode.

## 11. Auto-merge

See **`skills/automerging.md`**. Agent-authored PRs default
to draft → green CI → ready → squash-merge. The agent
subscribes to PR activity and reacts to CI failures via the
PR-comment channel from `skills/testing.md`. Required checks
are the full CI matrix minus jobs explicitly tagged
`continue-on-error: true` (which must reference an open
issue).
