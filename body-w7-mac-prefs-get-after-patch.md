## What changed and why

Fixes #22787.

`updateTranscriptionPreferences` PATCHes `/v1/users/transcription-preferences`, then GETs the same path and returns that body. The PATCH response is only `{status}`. If the GET fails after the PATCH succeeded (offline between the two calls, a decode error, a timeout), the function throws. The Custom Vocabulary pane treats that throw as a failed save and puts the previous list back, so a change the account stored looks unsaved. #22403 (merged) added that rollback. This change does not edit that pane.

After a successful PATCH, a failed GET is now logged and the function returns the values this call sent. The GET still wins when it succeeds.

## Product invariants affected

INV-MEM-5

The path glob matches `desktop/macos/Desktop/Sources/**`. This change does not alter memory or task authority. It only stops a saved transcription-preference write from being reported as a failure.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `updateTranscriptionPreferences` returns `try await getTranscriptionPreferences()` immediately after the PATCH. `TranscriptionVocabularySaver` maps any throw to `.failed` and restores the last confirmed list.
- No issue or open PR covers this read-back. #22781 changes the Settings switches and does not edit this function.
- The regression test was written to fail without the catch and runs in Omi CI (`Desktop Swift Build & Tests`) with `ci:full`. It has not been run locally.

## Tests

`desktop/macos/Desktop/Tests/APIClientMemoryMutationRequestTests.swift`, `testUpdateTranscriptionPreferencesKeepsTheSaveWhenReadbackFails`: the protocol answers the PATCH with `{status: ok}` and fails the following GET. The call must return the vocabulary it sent, not throw. On `main` the GET error propagates, so the test fails.

The existing test still checks that a successful GET is what the caller sees.

## UI evidence

UI-Evidence: none -- API client change; the protocol test covers the save result. The running app was not exercised locally.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-readback-failure-reported-as-save-failure`.

- Violated contract: a save the server has already accepted must not be reported as a failure because a later read of that value fails.
- Canonical guard: after the PATCH, a failed GET returns the sent values. The protocol test fails that GET and asserts the sent vocabulary comes back.
- Evidence: `return try await getTranscriptionPreferences()` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
