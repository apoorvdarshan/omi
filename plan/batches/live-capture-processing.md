# Batch: live-capture-processing

## Screens
- Live capture page (ConversationCapturingPage) reached from the native Home capture card, deep link and battery pill
- Processing conversation page (ProcessingConversationPage)
- Record options sheet and pendant-is-listening sheet (native Home record action)
- Live capture problem-details sheet

## Owned files (only these may be created/edited)
- app/lib/pages/conversation_capturing/page.dart
- app/lib/pages/conversation_capturing/conversation_capturing_native.dart
- app/lib/pages/conversation_capturing/capture_state_header.dart
- app/lib/pages/conversation_capturing/widgets/carried_speaker_banner.dart
- app/lib/pages/conversation_capturing/widgets/speaker_suggestion_chip.dart
- app/lib/pages/processing_conversations/page.dart
- app/lib/pages/home/widgets/battery_info_widget.dart
- app/lib/pages/conversations/widgets/live_capture_card.dart
- app/test/mobile/native_ui/native_live_capture_test.dart
- app/integration_test/native_live_capture_host_test.dart

## Instructions
The scouts missed this area; the parity ledger lists it as 'Detailed capture flows'. Common rules: Dart only. CaptureProvider, the capture controller, WAL upload, speaker-label APIs, MediaViewerPage and the name-speaker sheet stay the owners. Native code gets no audio or photo bytes. Flag-off behaviour is unchanged. Uses P0, P2 and the existing reader idiom from conversation detail (NativeReader following, scroll suspend). 1) ConversationCapturingPage: add part conversation_capturing_native.dart. When iosSwiftUiEnabled, return IosNativeSurface with title = the same display-state label ConversationStateAppBar shows (source label, buffering duration), fallback the current Scaffold, and toolbar back. Section 'capture_status': the recovery prompt projected from the existing wedge monitor, using the same handler as the native Home 'recovery' alert; the unsynced-WAL indicator as a label with the same copy as _buildUnsyncedWalIndicator, plus 'capture_wal_retry' calling retryFailedSessionWalUploads when retryable; and the carried-speaker banner as label rows with its existing actions. Section 'capture_timeline' in chronological order: transcript segments as kind 'transcript' rows 'capture_segment:<index>' (literal text, subtitle speaker label and time) with options {'identify': identifySpeaker} calling _nameSpeaker(segmentId, speakerId), the existing native sheet; speaker-suggestion accept and reject options calling the existing chip handlers; segments in taggingSegmentIds disabled; photo groups as navigation rows 'capture_photos:<index>' (title time · conversationPhotosCount) calling _openPhotoViewer (native MediaViewerPage; no thumbnails cross). When there are no segments or photos, empty = _liveCaptureEmptyStateText. reader: NativeReader(targetId = last row id, request = segmentsPhotosVersion, following true, scroll menu with 'suspend' when the user drags). footer: 'capture_pause' (pause.fill or play.fill, resume or pause, shown when LiveCaptureCard.canPause, enabled when !_mutePending && !isCallActive) calling _toggleMute, and 'capture_finish' (finish, checkmark) calling _stopConversation. 2) ProcessingConversationPage: IosNativeSurface reader with literal transcript rows and photo-group rows (to MediaViewerPage), title the processing state label, back. Empty is noContentToDisplay. Fallback is the current Scaffold. 3) battery_info_widget.dart: _showRecordOptions and _showPendantListening pass a nativeBuilder, an IosNativeSurface with button rows (phone mic and phone call; record with phone, phone call and keep pendant) whose actions pop the sheet, then call exactly the existing callbacks. 4) live_capture_card.dart: LiveCaptureCard.showDetails passes a nativeBuilder: an explanation label plus 'capture_details_ok' (gotIt) that pops. No new strings.

## Tests
native_live_capture_test.dart, with a fake CaptureProvider: timeline ordering of segments and photos; identify calls _nameSpeaker with the segment's ids; tagging segments disabled; the pause row visibility rules and the call-active disable; finish calls _stopConversation once; the unsynced-WAL label and retry; the empty-state copy variants; following and targetId advance with segmentsPhotosVersion; the record and pendant sheets call the same callbacks after pop; the details sheet pops. Host (native_live_capture_host_test.dart): open ConversationCapturingPage with seeded inert capture state, check native containment, footer Finish reaches the owner, and the processing page renders natively.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- M3/O4: you also own lib/pages/conversations/widgets/processing_capture.dart. ProcessingConversationPage must offer the timed-out 'Try again' (ProcessingConversationWidget._onRetry behaviour) natively and classically, so routing the library row to the page loses nothing.
- O5: reuse lib/pages/conversations/widgets/capture_recovery_banner.dart (add it to your owned files) rather than the inline closure in native_home_presentation.dart.
- Keep frozen signatures ProcessingConversationPage(conversation:), LiveCaptureCard.formatElapsed, HomeRecordButtonState.performPrimaryAction/showOptions.
