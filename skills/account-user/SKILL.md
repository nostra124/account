---
name: account-user
description: |
  Operate the `account` identity foundation — create /
  inspect / configure system + remote accounts, manage
  their SSH and GPG keys, query remote endpoints, check
  online status. Trigger when the user wants to add an
  identity, share a public key, set up SSH access between
  accounts, or learn how the `→ account` foundation
  direction shapes the whole collection.
---

# `account-user` skill

## 1. Design principles

`account` follows the four collection principles —
**educational, functional, decentralized, simple** —
specialised:

- **Educational.** Every subcommand maps onto a Unix
  primitive (sudoers, gpg, ssh-keygen, ssh-copy-id).
  Reading `bin/account` end-to-end teaches the underlying
  system identity model.
- **Functional.** Each verb is a pure transformation:
  read a key, list registered accounts, export a public
  key. Shared state lives in
  `$XDG_CONFIG_HOME/account/`.
- **Decentralized.** No central registry. Each host owns
  its own slaves list; remote accounts are reached via
  SSH + the configured endpoint — no central directory.
- **Simple.** `account` calls nothing in the collection
  at runtime. Everything else builds on top.

## 2. The model

`account` is **identity**. An *account* is the tuple of
(name, ssh-key, gpg-key, endpoint). The local host has
exactly one **identity** (the current Unix user). Other
accounts are **remote**: their public keys live under
`$XDG_CONFIG_HOME/account/{ssh,gpg}/<name>.pub` and
their endpoint is the SSH-resolvable name.

The `→ account` direction is the foundation property:
every other tool in the collection
(`config`/`secret`/`repo`/`cluster`/`bitcoin`/…) calls
`account` for identity needs; `account` calls none of
them.

What's *not* in scope: configuration storage (`config`),
secret material (`secret`), provisioning of system users
beyond the current user's identity (`user`).

## 3. Workflow recipes

1. **Bootstrap the local identity.**

       account init

   Generates `~/.gnupg/<user>.cnf`, creates the GPG
   keypair, generates an SSH key, sets sudoers, ensures
   `git config user.{name,email}` is set.

2. **Register a remote account.**

       account insert alice@example.com

   Copies the local SSH public key to alice's
   `~/.ssh/authorized_keys`, fetches alice's GPG and
   SSH public keys, signs the GPG key locally, and
   appends `alice@example.com` to
   `~/.config/account/slaves/<identity>`.

3. **Inspect registered accounts.**

       account list
       account has alice@example.com
       account online alice@example.com
       account status

4. **Share your public key.**

       account ssh-export-public-key | ssh-copy-id-friend
       account gpg-export-public-key | mail-to-friend

5. **Run a command on a remote account.**

       account exec alice@example.com -- some-command

6. **GPG-encrypt to a registered account.**

       echo secret | account gpg-encrypt alice@example.com

7. **Read the cache / config / data home dirs.**

       account cache-home          # ~/.cache/account
       account config-home         # ~/.config/account
       account data-home           # ~/.local/share/account

## 4. Guardrails

1. **Never run `account init` on a machine with an
   existing GPG key you care about.** It creates a new
   keypair if one doesn't exist; if one does, it
   leaves it alone — but verify before assuming.
2. **`account insert` requires the remote to be SSH-
   reachable** with `ssh-copy-id` semantics
   (`StrictHostKeyChecking=no`, `BatchMode=yes`). It
   will silently warn-and-skip if the remote is
   offline.
3. **Public keys live unencrypted under
   `$XDG_CONFIG_HOME/account/{ssh,gpg}/`.** Treat
   this dir like `~/.ssh`: keep it on a personal
   machine, not a shared filesystem.
4. **Don't `rm -rf $XDG_CONFIG_HOME/account/slaves/`
   to "reset"** — the slaves list is the authoritative
   record of which remote accounts trust this host.
   Re-bootstrapping a slaves list is manual.
5. **`account exec` runs over plain SSH.** No sandbox,
   no `sudo` indirection. Be deliberate about what you
   pipe into it.

## 5. Where to read more

- `man account` — full reference (synopsis, every
  subcommand, environment, files, exit status).
- `docs/account.md` — the CLI contract doc per FEAT-004.
- This package's `CLAUDE.md` — developer-side
  conventions, the no-shared-lib policy, intentional
  duplications.
