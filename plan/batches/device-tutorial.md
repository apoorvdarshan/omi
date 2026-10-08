# Batch: device-tutorial

## Screens
- Interactive device tutorial wrapper (close/skip, progress) and intro
- Tutorial steps: transcription demo, single press, voice reply, power cycle, double press, all set

## Owned files (only these may be created/edited)
- app/lib/pages/onboarding/interactive_device_onboarding/interactive_device_onboarding_wrapper.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/transcription_demo_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/single_press_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/voice_reply_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/power_cycle_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/double_press_config_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/steps/all_set_step.dart
- app/lib/pages/onboarding/interactive_device_onboarding/widgets/onboarding_intro_screen.dart
- app/lib/pages/onboarding/interactive_device_onboarding/widgets/onboarding_step_scaffold.dart
- app/lib/pages/onboarding/interactive_device_onboarding/widgets/double_tap_demo_animation.dart
- app/test/mobile/native_ui/native_device_tutorial_test.dart
- app/integration_test/native_device_tutorial_host_test.dart

## Instructions
Common rules: Dart only. DeviceOnboardingProvider (step machine, BLE button and transcript callbacks), CaptureProvider batch suspend/restore, MessageProvider, OmiVoicePlaybackService, the voice route source, SharedPreferencesUtil, updateUserOnboardingState and analytics stay in Dart. No microphone, BLE or TTS in native code. Flag-off behaviour is unchanged. Uses P0 (nativeAssetImageUri) and P2. 1) Wrapper: natively wrap the current step in NativeNavigationChrome with toolbar [NativeRow('device_tutorial_close', close, symbol 'xmark') calling _skipOnboarding]. After the intro, add section 'device_tutorial_progress' with NativeRow('device_tutorial_step', onboardingStepOf(n, 6), kind 'progress', value n, maximumValue 6). wrapFallback restores the classic gradient, close and progress-dots chrome. PopScope stays outside (system back means skip, persisting completion). Natively skip the AnimatedSwitcher and key each step, so the State, listeners and timers are exactly today's. 2) Each step's build returns IosNativeSurface(title, fallback the classic step). Intro: device art via nativeAssetImageUri (image row or label thumbnail), subtitle, duration label (clock), Get Started and Skip. Transcription demo: status label, the transcript as a literal label from demoSegments, a success label (checkmark.circle.fill) once complete, Continue only when _showContinue. Single press: a state label for waiting, listening or processing (symbols hand.tap, waveform, ellipsis.bubble); the question as a message_user row with plainText; the markdown-stripped answer as a message_ai row with plainText; Continue. Voice reply: 'dev_tut_preview' (play.fill or stop.fill, subtitle the output-route label) calling _togglePreview; three toggle rows 'dev_tut_mode_0..2' (value mode == i, description subtitle, single-select) calling _selectMode; a status label with a symbol per mode and route; the Settings hint; Continue; the preview stops on dispose. Power cycle: a substate label (power, bolt.horizontal.circle, checkmark.circle), the hold hint when _showHint, Continue after reconnect. Double press: one toggle row per action calling selectDoubleTapAction, hint and prompt labels, Continue once doublePressCount > 0 and no hint is shown. All set: navigation rows (title plus badge · current value) calling provider.goToStep, the replay hint, Finish calling the existing completion. 3) Decorative custom-painter animations (pulse rings, press bounce, glow, DoubleTapDemoAnimation) are not reproduced natively; static artwork, SF Symbols and the same instructional copy replace them, and the classic fallback keeps the animations. No new strings.

## Tests
native_device_tutorial_test.dart: drive DeviceOnboardingProvider directly (onTranscriptSegments, onButtonEvent, onDeviceDisconnected/Reconnected, selectDoubleTapAction) and snapshot each step projection, including the progress row and the close row; close persists deviceOnboardingCompleted through _skipOnboarding; voice reply with a fake outputRouteSource and playPreview: mode selection persists and Off behaves as today; the all-set rows call goToStep. Host (native_device_tutorial_host_test.dart): the tutorial opened from Device Settings with a fake provider renders natively, and close persists completion. Physical CV1 button verification is deferred.

## Depends on
None
