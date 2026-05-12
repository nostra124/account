---
id: FEAT-216
type: feature
priority: medium
status: done
---

# Milestone institution: versioned backlogs in `issues/ROADMAP-<X.Y.Z>.md`

## Description

**As a** maintainer planning work in chunks
**I want** a documented institution for assigning features
and bugs to a target release version
**So that** every change is traceable from spec → backlog
→ commit → ship, and one agent session can implement one
named milestone end-to-end without ambiguity.

The institution formalises what ROADMAP-1.1.0 / 1.2.0 /
1.3.0 demonstrated by example: group related issues into a
versioned file, work them all in one PR, mark done as you
go, delete the ROADMAP when complete (preserving history
in git), move closed issues into `done/` for permanent
traceability.

## Implementation

1. Write `skills/milestones.md` covering:
   - Why versioned backlogs.
   - The plan → implement → close lifecycle.
   - Shuffling issues between milestones.
   - The two directories (`issues/{bug,feature}/` vs
     `…/done/`) and how completed milestones disappear
     from the tree.
   - ROADMAP file format (frontmatter + body sections).
   - Single-session discipline.

2. Cross-reference from `skills/features.md`,
   `skills/bugs.md`, `skills/audit.md`, and CLAUDE.md §12.

## Acceptance Criteria

1. `skills/milestones.md` exists with all six body
   sections.
2. CLAUDE.md §12 references it.
3. `skills/features.md` and `skills/bugs.md` cross-link to
   it.
4. The institution is applied in this same PR: pre-existing
   `ROADMAP-1.{1,2,3}.0.md` files are deleted; their
   issues are moved to `done/`; a new ROADMAP-1.4.0 is
   filed listing this work.
