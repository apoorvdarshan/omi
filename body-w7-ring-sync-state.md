## What changed and why

Fixes #22789.

`RingStorageSync.syncWal` read the ring without setting `wal.isSyncing`, `syncStartedAt`, or `syncMethod`. The recording detail page renders Transfer to Phone until `isSyncing` is true, and only then shows progress, speed, ETA, and a Cancel button. During a ring transfer the page therefore looked idle, and the transfer could not be cancelled from it.

`syncAll` had no per-recording UI state either, but this change covers the explicit Transfer to Phone path. `syncWal` now marks the recording the sync UI reads (matched by storage and id, so a page opened before a relist still sees the update), sets the start time, publishes speed and ETA with progress, and clears every marker in `finally` on success or failure.

## Product invariants affected

INV-CAP-1

The path glob matches `app/lib/services/wals/**`. This change does not drop pendant audio. It only publishes transfer state so the user can see and cancel a ring transfer.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `RingStorageSyncImpl.syncWal` sets only the private `_isSyncing`, while `SDCardWalSyncImpl.syncWal` also sets `isSyncing`, `syncStartedAt`, `syncMethod`, `syncSpeedKBps`, and `syncEtaSeconds` on the matched `Wal`.
- `app/lib/pages/conversations/wal_item_detail/wal_item_detail_page.dart` reads `currentWal.isSyncing` for the Cancel button and `syncSpeedKBps`/`syncEtaSeconds` for progress.
- No open issue or PR covers this state.
- `dart format --language-version=3.0 --line-length 120` on the changed Dart files. The regression tests run in Omi CI (`flutter test`) with `ci:full`. They have not been run locally.

## Tests

`app/test/unit/ring_storage_sync_no_advance_test.dart`:

- `a transfer marks the listed recording as syncing for the whole read`: starts a transfer from a stale `Wal` instance with the same id and storage, asserts the listed instance is syncing with a start time while the read is in flight, and asserts it is synced with every transfer marker cleared afterwards. On `main` the listed instance never becomes syncing, so the first assertion fails.
- The existing read-failure test now also asserts the recording is not left syncing.

## UI evidence

UI-Evidence: none -- state publication fix; the regression test covers the fields the page renders. The running app was not exercised locally.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-device-transfer-state-unpublished`.

- Violated contract: a device transfer must publish its running state on the recording the sync UI reads.
- Canonical guard: `syncWal` marks the listed recording before reading and clears it in `finally`; the regression test asserts both edges.
- Evidence: `RingStorageSyncImpl.syncWal` on `origin/main` before this change set no `Wal` field. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)