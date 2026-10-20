# w7-go-whisper-stop

- **Issue**: https://github.com/BasedHardware/omi/issues/22770 (`#22770`)
- **PR**: https://github.com/BasedHardware/omi/pull/22771 (`#22771`)
- **Branch**: `fix/go-sdk-whisper-stop`
- **Fix Commit SHA**: `6241bd035d36e1f3074f592afd5f491892793fed`
- **Head SHA (`ci:full` trigger)**: `b1d55d1a2e87dc98462120752b35f2e346943ec1`

## Verification

- Confirmed `whisperBatch` in `sdks/device/go/omidevice/stt/stt.go` on `origin/main` (`31a07230bb2f7cdbb44bd03f952335f9692faf8d`) still lacked a `stopped` flag and accepted/transcribed audio appended after `Stop()`.
- Checked existing issues and PRs in `BasedHardware/omi` to confirm no duplicate existed for Go SDK `whisperBatch` accepting audio after `Stop`.
- Confirmed `fork/fix/go-sdk-whisper-stop` merges cleanly with `origin/main`.
- Filed issue `#22770`, updated `body-w7-go-whisper-stop.md`, opened PR `#22771`, attached the `ci:full` label, and pushed an empty commit (`b1d55d1a2e87dc98462120752b35f2e346943ec1`) to trigger full CI.
