## What changed and why

Fixes #22780.

In macOS Settings, the Daily Summary, Store Recordings and Private Cloud Sync switches change on screen as soon as they are flipped, then send that value to the account. When the request failed (offline, a server error, an expired session), the `catch` only logged it. The pane kept a setting the account never stored. The next Settings load showed the account's value again and the change was gone, with no message.

This is the same failure #22403 fixed for Custom Vocabulary. These three switches now keep the value the account last confirmed. A failed save puts that value back and shows "Couldn't save that setting. Try again." A newer flip made while a save is in flight decides what the pane shows. A Settings load that started before a flip does not overwrite it.

The Summary Time hour save still only logs a failure. That is a separate control and is not part of this change.

## Product invariants affected

none

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `updateDailySummarySettings`, `updateRecordingPermission` and `updatePrivateCloudSync` (`SettingsContentView+SettingsUpdates.swift`) caught the error and only called `logError`. The switches bind directly to `dailySummaryEnabled`, `recordingPermissionEnabled` and `privateCloudSyncEnabled`.
- Compared with #22403 (merged), which put the last confirmed vocabulary list back through `TranscriptionVocabularySaver`. This change adds `BooleanSettingSaver` beside it and does not edit that saver.
- `xcrun swiftc -parse` was not a useful check: these files depend on the app target. The regression tests were written to fail without the fix and run in Omi CI (`Desktop Swift Build & Tests`) with `ci:full`; they have not been run locally.

## Tests

`desktop/macos/Desktop/Tests/BooleanSettingSaverTests.swift`:

- `testFailedFlipPutsBackTheValueTheAccountHolds`: a refused flip of Store Recordings (or either sibling switch) returns `.failed(restore: false)` and the account still holds `false`. On `main` the pane kept `true` and the failure was only logged, so this outcome did not exist.
- `testFailedFlipBeforeSettingsReadTheAccountRestoresThePreviousSide`: with no confirmed value yet, the restore is the side the user flipped away from.
- `testSuccessfulFlipReportsTheStoredValue`: a write that succeeds returns `.saved(true)`.
- `testFailureIsLeftToANewerFlip`: a failure that is no longer the latest flip returns `.superseded`, so an older request cannot put the switch back over a newer one.

## UI evidence

UI-Evidence: none -- macOS Settings change; the regression tests above cover the save outcome, and the error line uses the existing recap-depth error style. The running app was not exercised locally.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-failed-settings-save-shown-as-stored`.

- Violated contract: a settings control that changes on screen before the account confirms the write must put the last confirmed value back, and say the change was not saved, when the write fails.
- Canonical guard: `BooleanSettingSaver.save` returns `.failed(restore:)` when `write` throws, and `BooleanSettingSaverTests` drives that path. The three switches apply that outcome to the value on screen.
- Evidence: the three `catch` blocks in `SettingsContentView+SettingsUpdates.swift` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance of this class. #22403 fixed the same symptom for vocabulary under a different class.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
