# Batch: recording-detail

## Screens
- Recording file detail (WalItemDetailPage): device transfer, local playback, options, info
- Local recording detail sheet (batch/offline LocalRecording)

## Owned files (only these may be created/edited)
- app/lib/pages/conversations/wal_item_detail/wal_item_detail_page.dart
- app/lib/pages/conversations/wal_item_detail/wal_item_detail_native.dart
- app/lib/pages/conversations/recording_detail/recording_detail_sheet.dart
- app/test/mobile/native_ui/native_recording_detail_test.dart
- app/integration_test/native_recording_detail_host_test.dart

## Instructions
Common rules: Dart only. SyncProvider (with its AudioPlayerUtils player) and LocalRecordingsProvider remain the only player, transfer, share and delete owners; no second player is created. No file paths or audio bytes cross the bridge, only waveform levels. Flag-off behaviour is unchanged. Uses P0 (optional device image via nativeAssetImageUri), P1 and P2. 1) WalItemDetailPage: new part wal_item_detail_native.dart. IosNativeSurface (fallback the classic page, same State) with title recordingDetails and toolbar [back, NativeRow('wal_more', moreOptions, kind 'menu', symbol 'ellipsis', options {info; transfer or share, not while transferring; delete, not while transferring})]. Header labels: date and time, and the storage notice (sdcard, memorychip or lock.shield). Transfer mode: a status label; progress row 'wal_transfer_progress' (subtitle '%, KB/s, ETA'); Transfer to Phone (transferWalToPhone; success toast and pop, or an error toast) or a destructive Cancel Transfer (cancelSync, info toast, pop); auto-pop when the WAL leaves device storage. Playback mode, following the conversation_playback_native idiom: 'wal_position' slider (maximumValue max(totalDuration, wal.seconds) in seconds; value currentPosition while playing, else 0; at most 200 normalized waveform points {x: (i + 0.5)/n * duration, y: level, label: ''}; subtitle 'm:ss / m:ss'; enabled while playing and canPlayOrShareWal) calling seekToPosition; 'wal_back10' (gobackward.10), 'wal_play' (play.fill or pause.fill, disabled with a processing subtitle while processing) and 'wal_fwd10' (goforward.10). info opens a non-alert showIosNativeModal with label rows (recording id, date and time, duration, format, storage, estimated size, device model, device id when not the phone, processed status) and close. delete uses the existing showOmiConfirm with processing-specific copy, then pops and deletes. share calls shareWalAsWav with a sharePositionOrigin from the screen rect. Stop playback on dispose. 2) recording_detail_sheet.dart: showRecordingDetailSheet gains nativeBuilder _RecordingDetailSheet(native: true): title date; toolbar close and 'rec_more' menu {share, info, delete unless busy}; the same slider and transport rows on a 200 ms position update; 'rec_process' (process now, or uploaded with a busy subtitle) handling every LocalUploadOutcome exactly as today (fair use, backend busy, failed with AppReviewService, started then close). While isPreparingShare, set loading true and disable every action row. Info via the label modal. No new strings.

## Tests
native_recording_detail_test.dart: projection for transfer and playback modes; the slider is disabled when not playing (seek dispatch refused); auto-pop when storage changes; menu options by state; non-finite durations or levels and more than 200 points fall back or clamp as specified; every LocalUploadOutcome is handled through native dispatch; the share overlay disables actions; delete pops after confirm. Host (native_recording_detail_host_test.dart): a seeded WAL opens the native detail and play/pause reaches the fake SyncProvider player.

## Depends on
None
