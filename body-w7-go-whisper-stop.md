## What changed and why

Fixes #ISSUE_NUMBER

`stt.NewWhisper` returns a `whisperBatch` with no stopped state. `Stop` flushes the buffered tail and clears the buffer, but the transcriber still takes audio afterwards. A chunk that reaches `AppendPCM` after `Stop` returned (for example a BLE frame already in flight when the caller stopped) is buffered as usual. Once the buffer reaches a full batch (160,000 bytes, five seconds of 16 kHz PCM16), `AppendPCM` runs the injected Whisper runner and calls `onTranscript` for a session the caller has already ended. A second `Stop` then flushes whatever was left.

- `whisperBatch` now has a `stopped` flag. `Stop` sets it before its final flush, so the audio accepted before `Stop` is still transcribed and delivered as before.
- `AppendPCM` checks the flag first. After `Stop` it returns `whisper transcriber stopped` without buffering, running the model or calling `onTranscript`. A repeated `Stop` has nothing left to flush and returns nil.
- Returning an error matches the Go SDK's websocket engines: after their `Stop` closes the socket, `AppendPCM` fails writing to it. The Dart, TypeScript and React Native Whisper engines already ignore audio appended after stop (`if (_stopped) return;` / `if (stopped) return;`).

Open PR #22301 changes the Parakeet part of the same file (`wsTranscriber`). This PR touches only `whisperBatch` and the stop tests, so the two don't overlap.

## Product invariants affected

none

## How it was verified

- Traced the path on current `origin/main` (`70f9bace79`): `NewWhisper`, `whisperBatch.AppendPCM` and `whisperBatch.Stop` in `sdks/device/go/omidevice/stt/stt.go`. `AppendPCM` appends unconditionally and runs the runner and `onTranscript` once the buffer reaches `batch`. `Stop` sets `buf = nil` but nothing stops later appends.
- Compared with the other SDKs' Whisper engines: `WhisperTranscriber.appendPcm` in `sdks/device/dart/lib/stt/stt.dart` and `createWhisperTranscriber` in `sdks/device/typescript/src/stt/index.ts` and `sdks/react-native/src/stt/whisper.ts` all return early once stopped.
- Checked the existing Whisper tests still hold: `TestWhisperRetainsBufferOnRunnerError` never calls `Stop`, and `TestWhisperRequiresRunner` only checks the nil-runner error.
- `gofmt -l` is clean on the changed Go files, and `scripts/failure-class validate` accepts the new definition and this body.
- I did not run `go test` locally. CI's `go-device-sdk-tests` lane (`go -C sdks/device/go test -race ./...`, triggered by `sdks/device/go/**`) runs the new test and the rest of the package on this PR with `ci:full`.

## Tests

`sdks/device/go/omidevice/stt/stt_stop_test.go`, `TestWhisperRefusesAudioAfterStop`: builds a `whisperBatch` with a 4-byte batch, like the neighbouring `TestWhisperRetainsBufferOnRunnerError`. It appends 2 bytes and stops, expecting one runner call and one transcript from the flush. It then appends a full 4-byte batch and stops again, expecting `AppendPCM` to return an error and the runner and handler to have seen only the audio from before the first `Stop`. On `main` the post-`Stop` append fills the batch, runs the runner a second time, delivers a second transcript and returns nil, so the test fails at the `AppendPCM` check. It was written to fail without the fix and runs in CI; it has not been run locally.

## UI evidence

UI-Evidence: none -- Go SDK library change with no UI; the regression test above covers the behaviour

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-stopped-transcriber-accepts-late-audio`.

- Violated contract: once a streaming transcriber's `Stop` has returned, audio appended afterwards must be refused, not buffered into a session nobody owns and transcribed after the caller has moved on.
- Canonical guard: `Stop` records a terminal stopped state before its final flush, and the input path checks it before touching the buffer. `TestWhisperRefusesAudioAfterStop` appends a full batch after `Stop` and checks that it is refused and never reaches the runner or the handler.
- Evidence: issue #ISSUE_NUMBER and `stt.go` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
