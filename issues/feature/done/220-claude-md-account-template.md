---
id: FEAT-220
type: feature
priority: medium
status: done
---

# Create `docs/templates/CLAUDE.md.account` — the per-package CLAUDE.md template

## Description

**As a** maintainer extracting future per-package repos
from the broader `scripts` collection
**I want** a versioned template that codifies the
`CLAUDE.md` structure of an extracted package
**So that** every new extraction starts from a known-good
shape (the same one this repo's `CLAUDE.md` evolved
through) instead of being reinvented per-package.

Carried forward from AUDIT-2026-05-12 as the second of
the two remaining ACs of FEAT-023.

## Implementation

1. Create `docs/templates/` if it does not exist.
2. Write `docs/templates/CLAUDE.md.account` mirroring
   the live `CLAUDE.md` section headers (1. Scope through
   12. Milestones and audits). For each section,
   include a one-paragraph guide for what package-specific
   content goes there, plus the `account`-specific text
   as a worked example.
3. Header references **`docs/templates/CLAUDE.md.foundation`**
   (the parent collection's foundation template) per
   FEAT-023 AC 6 wording.
4. Add a unit test that the file exists and references the
   foundation template:

       @test "FEAT-220: docs/templates/CLAUDE.md.account exists and references foundation template" {
           local template="$BATS_TEST_DIRNAME/../../docs/templates/CLAUDE.md.account"
           [ -f "$template" ]
           grep -q "CLAUDE.md.foundation" "$template"
       }

## Acceptance Criteria

1. `docs/templates/CLAUDE.md.account` exists.
2. The file references `docs/templates/CLAUDE.md.foundation`
   in its preamble.
3. Section headers 1-12 match `CLAUDE.md`'s outline.
4. The new bats test passes (85/85 with FEAT-219 in place).
5. FEAT-023 (which carried this AC) is closed in the same
   PR.
