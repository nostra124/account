---
id: FEAT-022
type: feature
priority: high
status: open
---

# Make `account` the foundation: flip cycles, no runtime deps, document duplication

## Description

**As a** maintainer preparing to extract `account` as its own rpk
package
**I want** `account` to sit at the very bottom of the dependency
stack — calling no other script in this collection at runtime
**So that** `account` can be installed first on a fresh machine and
every other script can declare a `.rpk/depends/account` constraint
without risking install-time chicken-and-egg cycles.

Today `account` calls: `cache check config data hosts repo rpk
scripts secret user`. Several of those call back into `account` —
`config`, `user`, `secret`, `repo`, `hosts` all have an
`→ account` edge of their own, forming hard cycles.

The corrected design:

- `account` is identity. Every other concept in the collection (a
  user, a secret, a repository, a host) is built *on top of*
  identity, so the `→ account` direction is the natural one.
- `account` calls **nothing** at runtime. The only declared
  dependency is `rpk` itself, and that exists for deployment
  metadata only — `account` never invokes `rpk` at runtime.

This requires accepting code duplication: any utility logic
`account` previously borrowed from `cache`, `data`, `config` is
inlined. The duplication is intentional and must be documented in
`CLAUDE.md` of every per-script repo so future contributors don't
"DRY it up" and silently re-introduce a foundation-breaking
dependency.

## Implementation

1. **Audit every call site in `bin/account`** that invokes another
   script and resolve each as follows:
   - `cache` — inline the cache-dir logic (`mkdir -p
     $XDG_CACHE_HOME/account`, `rm -rf` on `clean`).
   - `data` — inline the slice of `data`'s frame/store API that
     `account` actually uses.
   - `config` — flip: `account` reads/writes its own config files
     directly under `$XDG_CONFIG_HOME/account/`. `config` becomes
     the consumer (a higher-level orchestration script), not a
     library `account` depends on.
   - `hosts`, `repo`, `secret`, `user` — `account` no longer calls
     any of these. The reverse edges (those scripts → `account`)
     stay; touch each consumer script as needed to ensure the cycle
     is gone in this direction.
   - `check`, `scripts`, `rpk` — `check` is foundation, inline what
     `account` needs; `scripts` is removed entirely by FEAT-001;
     `rpk` is allowed as a deployment-only depend (declared in
     `.rpk/depends/`, never invoked at runtime).

2. **Verify** with
   `grep -wEn '(cache|check|config|data|hosts|repo|scripts|secret|user)' bin/account`
   that no script-call remains (only legitimate string/comment
   matches).

3. **Update consumer scripts** that previously had a cycle with
   `account` so the back-edge is the only direction left:
   - `config` → `account` is the new direction (kept).
   - `user`, `secret`, `repo`, `hosts` → `account` stays as needed;
     `account` → any of them is gone.

4. **Add `docs/templates/CLAUDE.md.foundation`** that every future
   per-script repo's `CLAUDE.md` derives from. Section: **Why this
   script duplicates code from siblings** — names the lifted
   snippets, names the sibling repo each came from, and explicitly
   forbids extracting a shared library.

## Acceptance Criteria

1. `grep -wEn '(cache|check|config|data|hosts|repo|scripts|secret|user)' bin/account`
   returns no script-invocation matches (only strings or comments).
2. `bin/account help` lists the same subcommands as before.
3. For each of `user secret repo hosts config`: that script still
   calls `account`, and `bin/account` no longer calls it.
4. `docs/templates/CLAUDE.md.foundation` exists and contains the
   no-shared-lib section.
5. Account smoke tests (or a minimal suite added in this ticket if
   none exist) still pass after the refactor.
