## What changed and why

Fixes #22783.

On Windows and Linux, `get_daily_recap` built every other section from the requested day, but the Memories section called `db.recentMemories(10)`. That returns the newest memories overall and ignores `days_ago`. A Yesterday or Past N days recap listed today's newest memories.

The recap now asks for memories created in `[from, to)` through `db.memoriesInWindow`, and drops any row outside that window. The extractor's dedup list still uses `recentMemories`. #22331 (merged) fixed the window start in this same function; this change does not touch that arithmetic.

## Product invariants affected

INV-CHAT-1, INV-MEM-5, INV-MEM-6

These match by path (`desktop/windows/src/main/agentKernel/**` and `desktop/windows/src/**`). This change does not alter the shared chat transcript, memory or task authority, or the knowledge ledger. It only limits which local memories a recap section prints.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `createGetDailyRecapExecutor` set `const memories = d.memories(10)` and `bindDailyRecapProd` implemented that as `db.recentMemories(limit)`, which selects `ORDER BY created_at DESC LIMIT ?` with no window. Conversations, tasks and insights in the same function already use `inWindow`.
- No issue or open PR covers the recap memories window. #22331 is merged and only changes `startOfDayOffset`.
- The regression test was written to fail without the fix and runs in Omi CI (`desktop-windows-ci`, path `desktop/windows/**`) with `ci:full`. It has not been run locally.

## Tests

`desktop/windows/src/main/agentKernel/productToolExecutorsTierB.test.ts`, `lists memories from the requested day, not the newest overall`: a Yesterday recap is given a memory from yesterday morning and one from today. It asserts the yesterday fact is listed, the today fact is not, and `memories` is called with yesterday's `[from, to)` and limit 10. On `main` the call is `memories(10)` and today's newest rows are printed, so the test fails.

The existing Today recap test now stamps its fixture memory inside today's window, and expects `## Memories (1)` instead of `## Memories (1 recent)`.

## UI evidence

UI-Evidence: none -- desktop tool output change with no UI; the regression test covers the recap text

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-recap-section-ignores-requested-window`.

- Violated contract: a daily recap section for a requested day must list rows from that window, not the newest rows overall.
- Canonical guard: `get_daily_recap` passes `[from, to)` to `memoriesInWindow`, and the Yesterday test asserts today's memory is absent.
- Evidence: `d.memories(10)` / `recentMemories` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
