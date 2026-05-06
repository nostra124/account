# `account`

> Identity foundation: GPG/SSH keys, git config, sudoers, plus a registry of remote accounts reachable from this host

## Install

    git clone https://github.com/nostra124/account
    cd account
    ./install --prefix=$HOME/.local

Or in two steps:

    ./configure --prefix=$HOME/.local
    make install

## Quick start

    account help
    account version

## Layout

| Path | Purpose |
|---|---|
| `bin/account` | the entry point |
| `libexec/account/` | sub-commands (where applicable) |
| `docs/account.md` | CLI contract reference |
| `share/man/man1/account.1` | man page |
| `share/doc/account/standards/` | vendored references (educational) |
| `skills/account-user/` | agent skill |
| `tests/unit/account.bats` | unit tests |
| `tests/sit/` | system integration (when present) |
| `.cpk/` | container packaging overlay |
| `.rpk/` | rpk metadata (version, versions ledger, depends/) |

## Documentation

- `man account`
- `docs/account.md` — CLI contract reference
- `share/doc/account/standards/README.md` — vendored standards
- `CLAUDE.md` — agent guide
- `skills/account-user/SKILL.md` — agent skill

## Conventions

This package follows the rpk per-script repo convention:

- Per-script repo: this repo contains only `account`'s artefacts.
- No shared library: helper boilerplate is duplicated, not factored out (see `CLAUDE.md` §4–5).
- Stow-based install via `make install`.
- Versioning: semver, with `.rpk/version` as the source of truth and `.rpk/versions` as the per-release SHA ledger.

## License

GPL-3 (per the cross-cutting policy in the parent `scripts` collection).
