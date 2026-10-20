## What changed and why

Fixes #22785.

An SD card read arms a 5 second timer for the first byte, then a 15 second stall timer on every packet. A packet can arrive after the listener is installed and before the 5 second timer is armed. That packet starts a 15 second timer. The 5 second arm then assigned over that timer without cancelling it, so the old timer was no longer the one later packets cancelled. It could still fire and abort a transfer that was receiving data. The same assignment is in the legacy read and the marker read.

Every arm now goes through `replaceTimer`, which cancels the timer it replaces. #22414 (merged) edits `syncWal` in this file; this change does not touch those lines.

## Product invariants affected

INV-CAP-1

The path glob matches `app/lib/services/wals/**`. This change does not drop pendant audio. It stops a replaced timeout from aborting an SD card read that is still receiving packets.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): both `_readStorageBytesToFileLegacy` and `_readStorageBytesToFileWithMarkers` cancel before the 15 second reassignment inside the packet callback, then assign `timeoutTimer = Timer(const Duration(seconds: 5), ...)` after `_writeToStorage` with no cancel. The `finally` only cancels the timer the variable still holds.
- No open issue or PR covers this timer replacement. #22414 is merged.
- `dart format --language-version=3.0 --line-length 120` on the changed Dart files. The regression test was written to fail without the cancel and runs in Omi CI (`flutter test`) with `ci:full`. It has not been run locally.

## Tests

`app/test/unit/sdcard_timeout_timer_test.dart`: arms a 5 second timer, replaces it with a 15 second timer through `SDCardWalSyncImpl.replaceTimer`, and elapses 6 seconds. The replaced timer must not fire. Elapsing the rest of the 15 seconds fires once. Without the cancel, the first timer fires at 5 seconds and the count is 1 before the second elapse, so the test fails.

## UI evidence

UI-Evidence: none -- device-sync timer fix with no UI

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-replaced-timer-left-running`.

- Violated contract: replacing a timeout timer must cancel the timer it replaces. Assigning over the variable leaves the old timer running.
- Canonical guard: `replaceTimer` cancels the previous timer, and `sdcard_timeout_timer_test.dart` elapses fake time past the replaced timer.
- Evidence: the two 5 second assignments in `sdcard_wal_sync.dart` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
