# Batch: preferences-shortcuts-wrapped

## Screens
- Data & Privacy with App Shortcuts (ShortcutsLink) on Siri-toolchain builds
- Assistant voice settings (voice picker, previews, response mode, read-aloud)
- Wrapped 2025 (generate, progress, error, all cards, per-card share)
- Conversation timeout picker
- Transcription Import configuration dialog (and JSON editor cap behaviour)

## Owned files (only these may be created/edited)
- app/lib/pages/settings/data_privacy_page.dart
- app/lib/pages/settings/voice_settings_page.dart
- app/lib/pages/settings/wrapped_2025_page.dart
- app/lib/pages/settings/wrapped_2025_native.dart
- app/lib/pages/settings/conversation_timeout_dialog.dart
- app/lib/pages/settings/transcription/transcription_dialogs.dart
- app/lib/pages/settings/transcription/json_editor_page.dart
- app/test/mobile/native_ui/native_preferences_test.dart
- app/integration_test/native_preferences_host_test.dart

## Instructions
Common rules: Dart only. Owners: SiriIntegration (Pigeon), AssistantVoicesApi plus OmiVoicePlaybackService (no native player), the wrapped API plus the share templates, SharedPreferencesUtil, and the TranscriptionSettingsPage config owner. Flag-off behaviour is unchanged. Uses P0, P2 and P7. 1) data_privacy_page.dart: remove the early return 'if (_shortcutsHintSupported && _appShortcutsAvailable) return classic' only when (await nativeUiCapabilities()).contains('shortcuts_link'); resolve that once in State. Then add section 'siri_shortcuts' after 'siri': label 'siri_shortcuts_hint' (askOmi, subtitle siriShortcutsSetupHint('Ask Omi', 'Question for Omi'), plus siriShortcutsSearchHint when _searchHintSupported) and NativeRow('siri_shortcuts_link', askOmi, kind 'shortcuts_link'). Without the capability, keep today's behaviour exactly. 2) voice_settings_page.dart: IosNativeSurface (fallback the current Scaffold) with loading _loading, failed _error != null (errorMessage somethingWentWrong) and onRefresh _load. Rows: 'voice_current' navigation (subtitle current voice name, enabled !_saving) opening the picker; 'voice_preview_current' (play.fill or hourglass, enabled when nothing is previewing) calling _preview. The picker's showOmiSheet<String> gains a nativeBuilder wrapped in ValueListenableBuilder(_previewing), with 'voice:<index>' rows (checkmark on the selected one) that pop the voice id and 'voice_preview:<index>' rows; closing stops the preview; the index maps to _voices captured at open. Also 'voice_mode', a choice {0,1,2} that applies the _showModeSheet logic (persist, revoke read-aloud on Off, analytics), and toggle 'voice_read_aloud' (turning it off revokes). Keep every _ownerChanged guard; a selected id not in the catalog shows the name without a check. 3) Wrapped 2025: new part wrapped_2025_native.dart with a list projection per status. notGenerated: label wrappedLetsHitRewind plus 'wrapped_generate' calling _generateWrapped. processing: label wrappedCreatingYourStory plus progress row 'wrapped_progress' (step, value pct clamped 0..1, subtitle percent). error: label plus 'wrapped_retry'. done: one NativeSection per card, with labels for numbers and text; progress rows per category instead of the pie chart; labels for days, moments, buddies, obsessions, movies and phrases; and 'wrapped_share:<card>' calling the existing _shareX. The first row of each card has onVisible calling _trackCardView(index). The share templates stay Flutter-painted through IosNativeSurface.nativeWrapper: Stack([platformView, if template Positioned(left: -10000, top: -10000, child: RepaintBoundary(key: _shareTemplateKey, child: template))]). Offstage does not paint, so it cannot be used. Add mounted and session-snapshot checks before applying poll results, and stop polling on a session change. A malformed result type falls back to classic. 4) conversation_timeout_dialog.dart: nativeBuilder IosNativeSurface with 'timeout:<value>' rows (title, description subtitle, checkmark on the current one) that pop the value; persistence and the toast are unchanged. 5) transcription_dialogs.dart showImportConfigDialog: native loop via showIosNativeModal (labels pasteJsonConfig and addApiKeyAfterImport, text row 'import_json' with maximumLength 262144, actions cancel, paste and import). paste reads Clipboard.getData in Dart and re-presents with that text. If the clipboard text exceeds 262,144 units, return it directly to the caller for import (Dart is uncapped) instead of re-presenting or truncating. null falls back to the existing dialog. 6) json_editor_page.dart: keep the documented fallback to the complete Flutter editor above 262,144 units. Verify the native page passes maximumLength 262144 and that Save stays disabled while the JSON is invalid. Add no new primitive. No new strings.

## Tests
native_preferences_test.dart: shortcuts_link is emitted only with both gates true; otherwise classic with the UIKit button or native without the card, matching current logic. Voice: picking a voice calls setPreference once; preview is disabled while another runs; mode Off revokes read-aloud; closing the picker stops the preview. Wrapped: projection per status; share rows call the matching _shareX; progress bounded; malformed data falls back; polling stops on session change. Timeout persists exactly one allowed value. Import: paste re-presents; an over-cap clipboard returns the text directly; cancel means no mutation. Host (native_preferences_host_test.dart): Wrapped share capture still produces a PNG with the platform view mounted; the voice settings native picker; the import modal paste loop with a fake clipboard. On a Siri-toolchain build, manually confirm ShortcutsLink opens Shortcuts.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- M5: you also own lib/pages/settings/settings_destinations.dart. openVoiceProfile wraps the native guided-voice surface in a Flutter Scaffold/AppBar; give the native path proper native chrome (back row) when opened from Settings/native Home without breaking onboarding chrome.
- Wrapped and other rich_text rows: raw server text must be escaped (nativeRichText escaping) and links go only through options (P5 policy).
