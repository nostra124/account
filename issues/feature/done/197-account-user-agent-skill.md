---
id: FEAT-197
type: feature
priority: low
status: done
---

# `account-user` agent skill

## Description

**As a** user delegating identity-management tasks to an
AI agent
**I want** a packaged skill that teaches the agent the
account model — identity foundation, SSH key setup, GPG
identity, remote-account topology, the `→ account`
direction every other script flips toward
**So that** an agent can create / inspect / configure
accounts and their SSH/GPG keys without the model
re-explained per session.

Mirrors the established pattern (FEAT-019 bitcoin-wallet,
FEAT-036 crypt-user, …). Per FEAT-192's mandate that every
per-script repo ships a skill.

## Implementation

Layout:

    skills/
    └── account-user/
        ├── SKILL.md
        └── opencode.md

`SKILL.md` frontmatter:

    ---
    name: account-user
    description: Operate the `account` identity foundation
      — create / inspect / configure system + remote
      accounts, manage their SSH and GPG keys, query
      remote endpoints, check online status. Trigger when
      the user wants to add an identity, share a public
      key, set up SSH access between accounts, or learn
      how the `→ account` foundation direction shapes the
      whole collection.
    ---

`SKILL.md` body covers (per FEAT-192's six-section
contract):

1. Design principles.
2. **Model**: account is the foundation; everything else
   in the collection calls account, account calls nothing.
   An account holds identity (name + SSH key + GPG key)
   and remote-endpoint info. `account remote-url <name>
   <purpose>` resolves SSH endpoints for sibling tools.
3. Workflow recipes:
   - create + provision a new account
   - SSH key setup; key rotation
   - GPG identity creation
   - resolve remote URL for another tool's push/pull
   - check online status
   - identity queries (current account, platform,
     admin-rights)
4. Guardrails:
   - Never log private SSH or GPG material.
   - Never modify another account's keys without
     `--force` + confirmation.
   - Verify the target account exists before remote-URL
     calls; missing target should fail clearly.
   - The `→ account` direction is invariant — a sibling
     script that calls account is normal; account calling
     a sibling is a bug, not a feature.
5. Where to read more: `man account`,
   `docs/templates/CLAUDE.md.account`.

Installation per the established pattern (FEAT-019 / 036
/ etc.).

## Acceptance Criteria

1. `skills/account-user/SKILL.md` and `opencode.md` exist
   with the sections above.
2. `make install` places the skill under standard agent
   directories.
3. `make install-skills-user` symlinks idempotently.
4. Guardrail "never log private SSH or GPG material" is
   called out as #1.
5. The `→ account` foundation invariant is explicit.
