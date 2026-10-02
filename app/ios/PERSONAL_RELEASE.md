# Personal iPhone Release install

This branch now uses the standard production native identity and shared app group after removing the personal Debug isolation overrides. It is for Apoorv’s phone, not App Store submission.

- Configuration: `Release-prod`, `OMI_APP_PROFILE=production`, production Firebase and `API_BASE_URL=https://api.omi.me/`.
- Bundle: `com.friend-app-with-wearable.ios12`; Omi team `9536L8KLMP`; callback `omi`.
- Shared group: `group.com.friend-app-with-wearable.ios12`, consistently used by the app, Siri and widget.
- Reuse `~/Library/Developer/Xcode/DerivedData/omi-device-release` for incremental builds.
- Install over the existing Omi app, preserving its container. Never uninstall the production app.
- After the Release install is verified, remove only `com.friend-app-with-wearable.ios12.development` (Omi Debug).

Use the existing `codemagic.yaml` release configuration and committed `setup/release-firebase` client files. The local mobile wrapper/validator supports only local-dev and mobile-beta dogfood builds and rejects the production profile. Production is the release-CI profile, validated by the app’s startup routing checks. The `mobile_beta` profile must not replace the daily app: it selects a different product serving API.

Keep local/generated Firebase, environment and signing outputs out of Git. Verify the installed Release opens without a debugger before finishing.
