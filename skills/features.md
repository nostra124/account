---
name: features
description: |
  Feature workflow for the `account` package — issue authoring
  conventions, the "as a / I want / so that" user-story
  template, acceptance-criteria discipline, dependency rules,
  ROADMAP grouping, and the "test belongs in the same commit"
  rule that mirrors the TDD discipline in `skills/bugs.md`.
---

# `account` — feature workflow

A feature is any new capability, refactor, or quality
improvement that isn't a fix for shipped-broken behaviour.
Bugs (see `skills/bugs.md`) come before features at the same
priority level when choosing what to work on.

## 1. File the issue first

Path: `issues/feature/<NNN>-<slug>.md`. Numbering is sequential
within the feature namespace (see `issues/feature/` for the
current high-water mark). Frontmatter:

    ---
    id: FEAT-NNN
    type: feature
    priority: high | medium | low
    status: open
    ---

Body sections, in order:

1. **Description** — the user-story preamble:

       **As a** <role>
       **I want** <capability>
       **So that** <user-facing outcome>

   Followed by 1-3 paragraphs of context. Be specific about
   the current state and what's wrong with it; that's what
   future readers need to understand the *why*.

2. **Implementation** — the plan, broken into numbered steps.
   Reference exact files and line numbers where possible.
   Avoid open-ended "and maybe also X" wording; if you mean
   "do X", file X as a separate feature.

3. **Acceptance Criteria** — a numbered list, every item
   verifiable by `tests/pre-push.sh`, a `grep`, or a manual
   one-liner the maintainer can run. "Code looks cleaner" is
   not an acceptance criterion; "function X has no callers
   outside file Y (verified by `grep -rl 'X(' --exclude-dir=tests`)"
   is.

## 2. Tests are part of the feature

The same TDD spirit from `skills/bugs.md` applies to features
that change observable behaviour:

- A new command? → unit test for it.
- A new subcommand flag? → unit test for it.
- A new exit-code contract? → unit test for it.
- A new file under `$XDG_CONFIG_HOME`? → unit test verifies
  the write path.

The test and the implementation land in the **same commit**
(or in a pair of commits where the test commit precedes the
implementation; both are acceptable). Don't merge a feature
whose tests will land "later" — that erodes the suite's
contract.

Pure-bash features should land sandbox-safe unit tests; the
SIT layer (`tests/sit/`) is reserved for features that
genuinely require an external tool or container.

## 3. The no-shared-lib invariant

`account` is the foundation (FEAT-022, CLAUDE.md §4). New
features must not call other scripts in the collection at
runtime. If a feature wants to "use" code from `config` or
`secret`, **inline** the slice of logic it needs and document
the duplication in `CLAUDE.md` §5.

This is checked by code review, not by tests, but the rule is
hard: feature PRs that introduce a `→ config` or `→ secret`
runtime edge will be reverted.

## 4. ROADMAP grouping

After a batch of related features is filed, group them into a
release roadmap document at `issues/ROADMAP-<version>.md`:

    ---
    id: ROADMAP-<version>
    type: roadmap
    version: x.y.z
    priority: high | medium | low
    status: open | done
    ---

The body holds a single table of the included issues plus a
**Delivery notes** section that records the chosen order and
any dependencies. A roadmap is `done` only when every issue in
its table reads `done`.

ROADMAP version bumps follow semver: a milestone of pure
internal quality improvements is a patch / minor bump
depending on whether it changes the CLI contract.

## 5. Acceptance Criteria rules of thumb

Good ACs are:

- **Falsifiable.** A reviewer can run a one-line command and
  read the answer.
- **Bounded.** No "and other related improvements".
- **Independent.** Multiple ACs can pass or fail
  independently. "All tests pass" is a weak AC; "the new test
  X.bats passes and N existing tests continue to pass" is
  strong.

If an AC requires "see code review", the AC is incomplete —
add a `grep` or a CI lint step that catches the regression.

## 6. Closing a feature

Same flow as bugs (see `skills/bugs.md` §4):

1. Tests pass locally (`tests/pre-push.sh`).
2. CI is green.
3. Issue frontmatter reads `status: done`.
4. ROADMAP row reads `done`.

The commit that closes the feature should update the
frontmatter in the same change as the implementation, so the
linkage from code to spec is preserved in git history.

## 7. Cross-references

- Bug workflow → `skills/bugs.md`
- Test layers and pre-push hygiene → `skills/testing.md`
- Logging conventions → `skills/logging.md`
- Auto-merge process → `skills/automerging.md`
