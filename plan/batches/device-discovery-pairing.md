# Batch: device-discovery-pairing

## Screens
- Connect device / discovery and pairing list (ConnectDevicePage, FindDevicesPage, FoundDevices)
- Apple Watch setup sheet and permission page
- Ray-Ban Meta setup sheet and HFP mic picker
- Connection guide sheet and per-device pairing sheet
- Bluetooth guidance alerts

## Owned files (only these may be created/edited)
- app/lib/pages/capture/connect.dart
- app/lib/pages/onboarding/find_device/page.dart
- app/lib/pages/onboarding/find_device/found_devices.dart
- app/lib/pages/onboarding/find_device/device_discovery_controller.dart
- app/lib/pages/onboarding/apple_watch_permission_page.dart
- app/lib/widgets/apple_watch_setup_bottom_sheet.dart
- app/lib/widgets/rayban_meta_setup_sheet.dart
- app/lib/widgets/rayban_meta_input_picker_sheet.dart
- app/lib/widgets/connection_guide_sheet.dart
- app/lib/widgets/device_pairing_sheet.dart
- app/lib/widgets/bluetooth_guidance_listener.dart
- app/test/mobile/native_ui/native_device_discovery_test.dart
- app/test/unit/device_discovery_controller_test.dart
- app/integration_test/native_device_discovery_host_test.dart

## Instructions
Common rules: Dart only. BLE scanning and connection (OnboardingProvider, DeviceProvider, ServiceManager.device), BluetoothReadiness, WatchRecorderHostAPI and RayBanMetaHostAPI stay in Dart. Do not edit providers or device_provider.dart. Only display names, short ids, badges and battery cross the bridge. There must never be two scan owners. Flag-off behaviour is unchanged. Uses P0 (nativeAssetImageUri), P1 and P2. 1) Behaviour-preserving extraction of DeviceDiscoveryController (new file) from _FoundDevicesState and FindDevicesPage._scanDevices/_scanAgain: tap routing (Apple Watch reachability, setup sheet or permission page, then scanAndConnectToDevice; Ray-Ban availability, registration and camera, setup sheet, rescan, handleTap; others via handleTap), the offline-saved-device toast with Try Again rescan, the firmware compatibility warning, and scan/rescan with BluetoothReadiness.ensureReady(discovery). The classic widgets delegate to it. 2) ConnectDevicePage.build returns IosNativeSurface(title connect, fallback the classic Scaffold, nativeOwner: _DiscoveryLifecycle). _DiscoveryLifecycle is an offstage widget owning the MessageListener (toasts, DEVICE_CONNECTED pop, goNext calling HomeNavigation.returnHome), initiateConnection('FoundDevices'), scan-on-mount and cancelActiveScan-on-dispose; on fallback it is not mounted and FindDevicesPage owns the scan as today. Toolbar: back and 'connect_settings' (gearshape, to DeviceSettings). Section 'connect_status': loading while scanning with no results; a label with searching or the found count (antenna.radiowaves.left.and.right); when connected, pairingSuccessful, the disambiguated name and a battery label (battery.25 when at or below 25). Section 'connect_devices': 'connect_device:<index>' buttons (an index into visibleDeviceList captured in the projection; title the disambiguated name; subtitle Saved/Offline plus connecting; enabled !isClicked; imageUri nativeAssetImageUri(DeviceUtils.getDeviceImagePath)) calling controller.tap, which re-validates that the device is still visible. Section 'connect_none' (enableInstructions): scan again (arrow.clockwise), how to pair, not now (only with includeSkip), contact support. Section 'connect_more' when not connected: get Omi device (safari plus analytics) and connection guide (info.circle). The firmware compatibility warning uses showOmiConfirmWithOptOut (dismissible false) or showOmiAlert for critical cases, persisting the opt-out only on confirm. 3) Side flows get a nativeBuilder, with the same State in native mode and unchanged timers, host APIs and pop results. AppleWatchSetupBottomSheet: labels with a loading flag, a primary button, cancel. RayBanMetaSetupSheet: one section per _SetupStep with label rows and buttons, auto-popping true when ready. RayBanMetaInputPickerSheet: 'rayban_input:<index>' rows mapped to the uid captured at projection time and re-checked against the current list before connecting, with 'Connecting' or error subtitles, plus retry and empty rows. ConnectionGuideSheet: 'guide_product:<product.id>' navigation rows with asset thumbnails calling the existing _onDeviceTapped (Ray-Ban goes to the input picker). DevicePairingSheet: an image or label for the product art, title and description labels, Done keeping the double pop, and Report an issue (Intercom plus analytics). AppleWatchPermissionPage: IosNativeSurface with back, labels and Grant / Continue / Need Help buttons. 4) bluetooth_guidance_listener.dart: guidance alerts use showIosNativeModal(alert): permission (notNow / openSettings), turn on (notNow / enableBluetooth with retryBlockedOperation), info (ok). Call dismissGuidance when not acted on, using P1 reasons; null falls back to the existing dialogs. Decorative ripple and device animation art are not reproduced. No new strings.

## Tests
device_discovery_controller_test.dart: Apple Watch and Ray-Ban branches with fake host APIs; offline toast with rescan; firmware warning opt-out persisted only on confirm. native_device_discovery_test.dart, with a fake OnboardingProvider: projection while scanning, with results (saved, offline, connecting), the empty state with and without includeSkip, the connected state; invalid or duplicate device ids fall back; taps route only for ids still present; the picker rejects a stale index after reload; guide product ids are unique and every asset passes the allowlist; Bluetooth guidance reasons map to dismissGuidance or retry. Host (native_device_discovery_host_test.dart): an injected device list with inert BLE; a row tap calls handleTap; DEVICE_CONNECTED pops; one scan owner in native mode.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- Keep frozen ConnectDevicePage() constructor.
