# Batch: firmware-ota

## Screens
- Firmware update page (update, rollback to stable, progress, success, failure)
- Firmware pre-flight checklist sheet
- Firmware update available prompt and pairing-lost alert
- OmiGlass Wi-Fi OTA update
- Developer firmware flash page

## Owned files (only these may be created/edited)
- app/lib/pages/home/firmware_update.dart
- app/lib/pages/home/firmware_mixin.dart
- app/lib/pages/home/firmware_update_dialog.dart
- app/lib/pages/home/omiglass_ota_update.dart
- app/lib/pages/settings/developer_firmware_flash_page.dart
- app/lib/providers/device_provider.dart
- app/test/mobile/native_ui/native_firmware_test.dart
- app/integration_test/native_firmware_host_test.dart

## Instructions
Common rules: Dart only. FirmwareMixin's page State, NordicDfu/mcumgr, OmiGlassConnection, DeviceProvider and the FirmwareUpdatePromptCoordinator stay the owners. Never create a second State during DFU; the native projection is built from the same State's build(). zip URLs, firmware bytes, device addresses and saved Wi-Fi passwords never enter routine snapshots. No real flashing in CI. Flag-off behaviour is unchanged. Uses P0, P1 (dismissSignal, reasons) and P2. 1) FirmwareUpdate: build() returns PopScope(canPop: !busy, child: IosNativeSurface(title firmwareUpdate or stableFirmware for rollback, fallback the classic Scaffold from the same State, toolbar busy ? [] : [back], loading isLoading)). Sections by state. Update: version labels 'fw_current' (cpu, highlighted copy when outdated) and 'fw_latest' (icloud.and.arrow.down); 'fw_up_to_date' or already-on-stable or unable-to-determine; changelog as one rich_text row of text blocks with a bullet prefix (server text literal); a battery gate label (battery.25) when below kFirmwareUpdateMinBattery and not charging; 'fw_start' (Update Now / Install Update / Install Stable Firmware, only when allowsOmiFirmwareUpdate, disabled under the gate) calling the existing start, including the risky-3.0.17 confirm; 'fw_guide' when no update is needed. Busy: progress row 'fw_progress' 0..100 (title downloading or installing, subtitle percent) plus a warning label. Success: label plus 'fw_done' (resetFirmwareUpdateState, then HomeNavigation.returnHome). Failure: a download or install message plus 'fw_retry' and 'fw_support'. Keep setOnFirmwareUpdatePage, killMcuUpdateManager and telemetry. 2) firmware_update_dialog.dart showFirmwareUpdateSheet: a non-alert showIosNativeModal with checklist labels (powerplug, wifi, filtered as today) plus the warning label, actions cancel and start; 'start' calls onUpdateStart unawaited; null falls back to the classic sheet. 3) device_provider.dart showFirmwareUpdateDialog: showIosNativeModal(alert, dismissible false, cancelId 'later', actions later and update) with dismissSignal completed through the coordinator's attachDismissal. 'update' runs the existing accept branch (setFirmwareUpdateInProgress, push OmiGlassOtaUpdate or FirmwareUpdate by device type), reason 'cancel' defers, 'programmatic' does neither, and whenComplete calls coordinator.complete. The pairing-lost dialog becomes showOmiAlert(barrierDismissible: false), keeping the _pairingLostDialogShowing de-duplication. null falls back to the existing ConfirmationDialog and showDialog. 4) OmiGlassOtaUpdate: IosNativeSurface inside PopScope(canPop: !_isUpdating) with sections per _buildContent branch: versions, the changelog split by newline, a 'progress' row when _progress > 0 (otherwise loading plus a status label), the warning, and the status-code-to-text mapping unchanged. Wi-Fi rows: 'ota_ssid' text (maximumLength 128) setting the controller. The password follows the STT secure idiom: NativeRow('ota_password:<revision>', password, kind 'text', keyboard 'password', value '', subtitle savedPasswordWillBeUsed while a saved password exists and is untouched) setting _passwordController. An explicit Show password reveals only the current typed draft. Clear bumps the revision. Reset the reveal on session events. Buttons: install, cancel update (destructive), done, try again, contact support, all calling the existing methods. 5) DeveloperFirmwareFlashPage: PopScope(canPop: !flashing, child: IosNativeSurface) with toolbar back when not flashing; a file label (doc.zipper, display name only); the warning; a destructive flash button calling startMCUDfu; a progress row; success and error labels. No new strings.

## Tests
native_firmware_test.dart, setting mixin fields (isLoading, shouldUpdate, isDownloading, isInstalling, isInstalled, updateFailure, latestFirmwareDetails): projection per state; no back row while busy; start disabled under the battery gate; the pre-flight modal 'start' calls onUpdateStart once; the coordinator retract completes dismissSignal so the result is programmatic and nothing is pushed or deferred; accept pushes the correct page by device type; pairing-lost de-duplication. OTA: the projection JSON never contains the saved password unless revealed; typed input updates the controller; Clear increments the row id; no back while updating; status mapping per OmiGlassOtaStatus with a fake connection. Flash page has 4 states. Host (native_firmware_host_test.dart): FirmwareUpdate with a stubbed getLatestFirmwareVersion renders natively; the prompt alert goes through the native presenter.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- V6: converting the pairing-lost dialog to showOmiAlert must pass okLabel: l10n.gotIt (unchanged flag-off wording).
- 'savedPasswordWillBeUsed' does not exist in app_en.arb and batches add no strings: reuse an existing key or keep that hint on the Flutter path; report it.
- Real firmware flashing is never performed in tests; use injected mixin states and stubbed APIs.
