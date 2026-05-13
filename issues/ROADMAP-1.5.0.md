---
id: ROADMAP-1.5.0
type: roadmap
version: 1.5.0
priority: medium
status: done
---

# Release 1.5.0 — packaging completion (close FEAT-023)

The two remaining acceptance criteria of FEAT-023 (the
self-contained-packaging epic) carried forward from
AUDIT-2026-05-12. Closing both lands `account` as a
truly self-contained per-package repo: every shipped
subcommand discoverable via tab-completion, and a
versioned template that codifies the package's CLAUDE.md
structure for future extractions.

## Issues

| ID | Type | Priority | Title | Status |
|----|------|----------|-------|--------|
| [FEAT-219](./feature/done/219-refresh-bash-completion.md) | feature | medium | Refresh `etc/bash_completion.d/account` to cover every shipped subcommand | done |
| [FEAT-220](./feature/done/220-claude-md-account-template.md) | feature | medium | Create `docs/templates/CLAUDE.md.account` — the per-package CLAUDE.md template | done |
| [FEAT-023](./feature/done/023-account-self-contained-package.md) | feature | high | Account self-contained packaging (close when 219+220 land) | done |

## Delivery notes

- **Order**: FEAT-219 first (it has a TDD test that pins
  the contract); FEAT-220 second (additive doc file).
  Both can land in a single PR; FEAT-023 closes when both
  do.
- **Test discipline** per `skills/features.md`: each FEAT
  has at least one bats test asserting its AC. FEAT-219's
  test is structural ("every command:<verb> has a
  completion entry"); FEAT-220's test is existence +
  reference-to-foundation.
- **Housekeeping** when this PR lands: delete
  `issues/ROADMAP-1.4.0.md` (still in-tree from the
  previous milestone close, awaiting the new-milestone
  PR to remove it per `skills/milestones.md` §2 Close);
  move FEAT-219, FEAT-220, FEAT-023 into
  `issues/feature/done/`.
