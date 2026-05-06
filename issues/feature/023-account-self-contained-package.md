---
id: FEAT-023
type: feature
priority: high
status: open
---

# Account self-contained packaging: docs, tests, man page, completion, CLAUDE.md

## Description

**As a** maintainer about to extract `account` to its own rpk repo
**I want** every artefact a standalone rpk repo expects — man page,
unit tests, CLI contract doc, bash completion, `CLAUDE.md` — present
and verified inside this repo first
**So that** the extraction (FEAT-024) is a mechanical move of files,
not a "now we also have to write the man page" exercise.

Mirrors the layout of `nostra124/rpk`. This ticket assembles every
piece in place; FEAT-024 then carves them out together.

## Implementation

Depends on FEAT-022 (`account` is the foundation) and the `account`
slice of FEAT-001 (the `bin/scripts` plugin loader removed for
`account`'s subcommands). Both should land before this.

For `bin/account`:

1. **Move `etc/scripts/account/*` → `libexec/account/*`** per
   FEAT-001. Each subcommand stays as its own executable file;
   `bin/account`'s dispatcher does a local `libexec/account/`
   lookup. No inlining. If FEAT-001 hasn't completed
   collection-wide yet, do the `account` slice here.
2. **`docs/account.md`** per FEAT-004's template: synopsis,
   description, every subcommand with args / env / exit codes,
   environment variables, files, exit codes, cross-script
   dependencies (after FEAT-022 this list is empty at runtime;
   `rpk` is listed as a deployment-only depend).
3. **`tests/unit/account.bats`** per FEAT-003: covers every
   documented subcommand including failure-mode exit codes.
   Sandboxed `$HOME` per test (rpk pattern).
4. **`share/man/man1/account.1`** (groff): NAME, SYNOPSIS,
   DESCRIPTION, SUBCOMMANDS, ENVIRONMENT, FILES, EXIT STATUS,
   EXAMPLES, SEE ALSO. Seeded from `bin/account`'s `help` output
   and `docs/account.md`.
5. **`etc/bash_completion.d/account`** — already exists; verify it
   completes every subcommand currently exposed by
   `bin/account help` and extend if not.
6. **`docs/templates/CLAUDE.md.account`** — the `CLAUDE.md` that
   will live in the extracted account repo. Sections: scope
   (identity primitives only), the no-shared-lib policy (lifted
   from `docs/templates/CLAUDE.md.foundation` per FEAT-022), what
   is intentionally duplicated and from where, who consumes this
   package.

## Acceptance Criteria

1. `bin/account` contains zero `scripts has` / `scripts list`
   invocations; its dispatcher looks under `libexec/account/`
   directly.
2. `docs/account.md` exists and lists every subcommand from
   `account help`.
3. `bats tests/unit/account.bats` passes.
4. `man -l share/man/man1/account.1` renders with all sections
   populated.
5. Tab completion works for `account <TAB>` and for every
   subcommand that takes arguments.
6. `docs/templates/CLAUDE.md.account` exists and references the
   foundation template.
