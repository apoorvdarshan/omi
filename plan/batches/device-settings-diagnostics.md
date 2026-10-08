# Batch: device-settings-diagnostics

## Screens
- Device Settings: double-tap action, LED brightness and mic gain inline controls
- Device Settings: Ray-Ban Meta full-page fallback fix, disconnected explanation, device thumbnail
- Device diagnostics: send-to-support review and ticket dialogs

## Owned files (only these may be created/edited)
- app/lib/pages/settings/device_settings.dart
- app/lib/pages/settings/device/device_control_sheets.dart
- app/lib/pages/settings/device/device_info_groups.dart
- app/lib/pages/settings/device/device_page_header.dart
- app/lib/pages/settings/device_diagnostics.dart
- app/test/mobile/native_ui/native_device_settings_test.dart
- app/integration_test/native_device_settings_host_test.dart

## Instructions
Common rules: Dart only. BLE writes stay in DeviceSettings through ServiceManager.device.ensureConnection; diagnostics upload stays in Dart via makeApiCall. Native code sends only bounded numbers and option ids. Flag-off behaviour is unchanged. Uses P0 (asset thumbnails and the settings symbol map) and P1. 1) Ray-Ban fix: resolve _rayBanMetaCameraStatus into a State String (setState on completion) and pass a plain label to DeviceInfoGroups through a new optional rayBanCameraLabel, so every child is an OmiSettingsRow. Today the FutureBuilder forces the whole Device Settings page to classic. 2) Give the double-tap, LED and mic gain OmiSettingsRows ValueKeys ('device_double_tap', 'device_led', 'device_mic_gain') and post-process the nativeSettingsSections output by id. Double tap becomes a choice {0,1,2} persisting SharedPreferencesUtil.doubleTapAction. LED becomes a slider (maximumValue 100, subtitle '<n>%'). Mic gain becomes a slider (maximumValue 8, subtitle level label · description) plus preset buttons Quiet, Normal and High (2, 4, 6). Dart rounds slider values and applies a trailing 300 ms debounce (cancel and restart with the latest value) before the existing _updateDimRatio and _updateMicGain writes, so the final value is always written. The classic page keeps device_control_sheets.dart. 3) When !isConnected, add the disconnected explanation (deviceNotConnected / connectDeviceMessage) as a label in the status section, plus a device thumbnail via nativeAssetImageUri. 4) device_diagnostics.dart _sendToSupport: the review is a non-alert showIosNativeModal (a description label plus a rich_text row with one code block of the pretty-printed JSON; actions cancel and send), keeping dialogCancelled analytics; a bundle over 256 KB keeps the Flutter dialog. The ticket is a non-alert native modal with a selectable label row plus acknowledge. null falls back to the existing dialogs. No new strings.

## Tests
native_device_settings_test.dart: a Ray-Ban paired device now yields a non-null native projection (regression); a slider burst writes the final value exactly once after the debounce; the choice rejects values outside the options; presets map to 2, 4 and 6; the disconnected label appears only when disconnected; diagnostics send calls the upload once, cancel records telemetry, and an oversized bundle uses Flutter. Host (native_device_settings_host_test.dart): native Device Settings with a fake paired Ray-Ban device stays native; a slider change reaches the fake device writer.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- LED brightness and mic gain use the new P8 'level' row kind (labelled, discrete, commit on release), not the playback 'slider'.
- Keep frozen DeviceSettings() constructor and FirmwareUpdate/OmiGlassOtaUpdate routing.
