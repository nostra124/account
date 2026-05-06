# account(1)

**Stable API — semver applies** (per FEAT-005).

## Synopsis

    account <options> <command> [args]

## Description

`account` is the **identity foundation** of the collection. Every
other script that needs identity (current user, current GPG/SSH
key, list of remote accounts, online status of a peer) calls
`account`; `account` calls nothing in this collection (per
FEAT-022's foundation rule). It manages:

- The local account's identity (username / hostname / domain).
- GPG keys (secret + public, encrypt / decrypt, import / export).
- SSH keys (public / known-host, import / export).
- A registry of known remote accounts plus their connectivity
  state (`has`, `online`, `status`).
- Master / slave relationships among accounts.
- Per-account directory layout (`home`, `cache-home`,
  `config-home`, `data-home`, `share-home`, `source-home`,
  `backup-home`).

## Options

| Flag | Effect |
|---|---|
| `-d` | enable debug mode (verbose stderr) |
| `-q` | enable quiet mode |

## Subcommands

### Generic
- `help [<cmd>]` — usage text; per-subcommand help if `<cmd>` given.
- `version` — print the version constant.

### Local account
- `init` — initialise the local account (creates directories,
  generates key material).
- `backup` — back up identity files (gpg/ssh).
- `identity` — print the local account identity (the canonical
  string used as `<account>` everywhere else).
- `admin` — exit 0 if the local account has admin rights.
- `username` / `hostname` / `nodename` / `domainname` — print
  the corresponding component.

### User mgmt
- `create-user <user>` / `delete-user <user>` — create / delete
  system users (under `/var/lib/<user>` per the current setup).
- `add-user <user> <group>` — add a system user to a group.

### GPG
- `gpg-secret-keys` / `gpg-public-keys` — list key identities.
- `gpg-encrypt [<accounts>...]` — encrypt stdin → stdout to the
  named accounts (defaults to local).
- `gpg-decrypt` — decrypt stdin → stdout.
- `gpg-export-secret-key [<key>]` / `gpg-export-public-key [<key>]`
  — export to stdout.
- `gpg-fingerprint [<key>]` — print the fingerprint.
- `gpg-export-owner-trust` — export the trust database.
- `gpg-import-public-key <key>` / `gpg-import-key [<key>]` — import
  from stdin or file.
- `gpg-delete-key <key>` — delete from gpg database.

### SSH
- `ssh-public-keys` — list public keys.
- `ssh-export-secret-key` / `ssh-export-public-key [<key>]` —
  export.
- `ssh-import-public-key <key>` — import.
- `ssh-export-known-host [<key>]` / `ssh-import-known-host` —
  known_hosts management.

### Remote accounts
- `list` — list known remote accounts.
- `insert <account> <gpg> <ssh>` — register a remote account
  with its gpg + ssh keys.
- `remove <account>` — unregister.
- `has <account>` — exit 0 if both gpg + ssh keys are known.
- `has-gpg-key <account>` / `has-ssh-key <account>` — finer
  granularity.

### Per-account paths
- `home [<account>]` — `~` for the local account, otherwise the
  remote's home.
- `cache-home / config-home / data-home / share-home / source-home / backup-home [<account>]`
  — per-account standard XDG-shaped paths.

### Master / slave
- `master` — list master remote accounts.
- `allow <account>` / `deny <account>` — grant / revoke a remote's
  master rights.
- `slaves [<account>]` — list slaves of an account.
- `insert-slave <account>` / `remove-slave <account>` — manage.
- `online` — list online remote accounts.
- `online <account>` — exit 0 if reachable.
- `status` — connectivity report.

### Synchronisation
- `pull <account>` / `push <account>` — push or pull this
  account's state to/from a remote.
- `sync <account>` — pull then push.
- `upgrade [<account>]` — apply package upgrades (delegates to
  the installed `rpk`).
- `update <account>` — sync configuration.

### Platform detection
- `platform` — print the running platform (`alpine`, `debian`,
  `ubuntu`, `fedora`, `arch`, `macos`, …).

### Remote-URL resolution
- `remote-url <account> [<purpose>]` (per FEAT-044) — print the
  canonical SSH URL for a sibling tool's push/pull. `<purpose>`
  is optional and namespaces the path (e.g. `password-store`,
  `cluster-config`, `bitcoin-wallet/<name>`). Used by
  `secret`/`config`/`bitcoin`/etc. instead of hand-constructing
  SSH paths.

## Environment

| Variable | Purpose |
|---|---|
| `SELF_DEBUG` | when set, enable `set -vx`-style trace |
| `SELF_QUIET` | when set, suppress info-level output |
| `XDG_CONFIG_HOME` | overrides `$HOME/.config` for config files |
| `XDG_DATA_HOME` | overrides `$HOME/.local/share` |
| `EUID` / `USER` | sourced if not set; used in path resolution |

## Files

- `$XDG_CONFIG_HOME/account/` — per-account configuration.
- `$XDG_DATA_HOME/account/` — per-account state.
- `~/.gnupg/` — managed via the `gpg-*` subcommands.
- `~/.ssh/` — managed via the `ssh-*` subcommands.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | success |
| non-zero | error; exact code conveyed via `fatal` calls in source |

## Cross-script dependencies

After FEAT-022 (foundation prep), `account` calls **nothing** in
this collection at runtime. It only invokes external tools (`gpg`,
`ssh-keygen`, `ssh`, `curl`, etc.) and depends on `rpk` as
deployment metadata.
