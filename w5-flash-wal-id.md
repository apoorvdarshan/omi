# w5-flash-wal-id

- Issue: https://github.com/BasedHardware/omi/issues/22416 (filed this run; nothing was filed before)
- PR: https://github.com/BasedHardware/omi/pull/22417 (created without --label, `ci:full` added via the issues API, then the empty commit was pushed)
- Fork branch: `fix/limitless-stable-recording-id`
- PR head: `b8d091ea27e03ffc2636aa53b969d5c235a66a70` (empty `ci: run with ci:full`) on fix commit `098c46577d13f57469dc544ed04e1c47f37e0e2a`; base `501f906eac` (older main, not rebased; the files involved are unchanged on main `c88d8b5937`)
- watch.inbox: `22417 w5-flash-wal-id fix/limitless-stable-recording-id`
- CI: not awaited (batch override); the watcher owns it.

## Worktree / environment note

`/Users/apoorvdarshan/omi/w5-flash-wal-id` was removed (`git worktree remove`) at about 11:51 by a separate disk-cleanup Claude session (zsh PID 6004 under `claude` PID 28428). The same script ran `rm -rf ~/omi/repair-evidence`, deleting BRIEF.md, loop-ci-watch.sh, every earlier record, watch.inbox and the resume-kit. The branch and commit survived. I finished without recreating a worktree: git plumbing in `/Users/apoorvdarshan/omi/repository` (push, `commit-tree`, `update-ref`; no working-tree changes) plus drafts in my scratchpad. I recreated only `repair-evidence/omi-loop/` with `watch.inbox` and this file.

The empty CI commit `b8d091ea27` is unsigned (`git commit-tree` did not apply `commit.gpgsign`). The fix commit is SSH-signed. No branch rule visible on upstream `main` requires signatures. Replacing the commit would need a force-push, so I left it.

## What I verified (code reading and cheap checks only; no local tests)

- The bug is present on origin/main `c88d8b5937`: `flash_page_wal_sync.dart:178` sets `timerStart = now - estimatedSeconds` on every listing, and `wal.dart:269` sets `id = device_timerStart`. The list is rebuilt by connect (`setDevice`), the coordinator's discover pass on every foreground pass (`recording_transfer_coordinator.dart:351-353`), and Sync (`wal_syncs.dart:332`, `flash_page_wal_sync.dart:288`). Id lookups that miss after a rebuild: `wal_item_detail_page.dart:140,494`, `deleteWal :140`, and `sync_page.dart:142` row keys.
- Duplicates: no issue or PR by anyone. The only open PR touching the file is our #22370, which edits `syncWal` (lines 313-340). This fix touches lines 102 and 175-185, so the two diffs don't overlap.
- The fix reuses `timerStart` from the listed WAL with the same device and `storageOffset == oldest page`. `_syncWal` moves `storageOffset` in place on cancel (`:567`) and on a partial download (`:684`), so the rest keeps its id.
- The seam change (`_testConnection ?? ensureConnection`) in `_getStorageStatus` and `_getMissingWals` matches `_syncWal :350`. Production never sets it. Existing `testConnection` users (`legacy_storage_limitless_seam_test.dart`) never reach `_getStorageStatus` inside `_syncWal`, so they are unaffected.
- Test APIs checked: `getStorageStatus()` returns `Future<Map<String,int>?>`, and `getDeviceInfo()` returns `Future<Map<String,String>>`. `BtDevice.getDeviceInfo` goes to `_getDeviceInfoFromLimitless` (inside a try). `setMockInitialValues({})` + `SharedPreferencesUtil.init()` is the same pattern other unit tests use, and `firstOrNull` comes from dart:core. Without the seam, `ServiceManager.instance()` throws in tests.
- `dart format --language-version=3.0 --line-length 120` reported no changes. Both JSON files parse. The FC definition has the required fields, and its scope hints and artifact exist. The changelog fragment follows `app/changelog/README.md`. INV-CAP-1 is named in the PR body. The line-count ratchet (1500 lines) does not apply: the file has 846 lines.

## Leads

- `app/lib/services/wals/ring_storage_sync.dart:219`: the same pattern. `refreshWalsFromDevice` sets `displayTimerStart = now - estimatedSecs` on every refresh (Offline Sync open via `discoverDeviceWals`, coordinator wakes), so the ring recording's id and start time change on each refresh.
- `app/lib/services/wals/sdcard_wal_sync.dart:192`: the same fallback (`now - seconds`) when the device reports no file timestamp (legacy SD-card firmware).

## Cleanup

The worktree is already gone. The local branch is at `b8d091ea27` in `/Users/apoorvdarshan/omi/repository` (== PR head). Delete it with `git -C /Users/apoorvdarshan/omi/repository branch -D fix/limitless-stable-recording-id` once CI is green.
