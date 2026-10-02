# Personal iPhone debug build

This branch prepares Apoorv's separate `Omi Debug` installation. It is not a release configuration.

- Configuration: `Debug-prod`, with `OMI_APP_PROFILE=mobile_beta` and web authentication.
- Bundle: `com.friend-app-with-wearable.ios12.development`; Omi team `9536L8KLMP`.
- Shared app group: `group.com.friend-app-with-wearable.ios12.development`, used consistently by the app, Siri and widget. It must not share the App Store app's group.
- Reuse `~/Library/Developer/Xcode/DerivedData/omi-device-debug` for incremental builds.
- Install only the debug identity. Never uninstall or clear `com.friend-app-with-wearable.ios12`.

Run `setup_app_env mobile_beta` from `app/setup.sh`, install the committed production Firebase client configuration, and run `app/scripts/validate_mobile_build_config.sh --flavor prod --profile mobile_beta` before building. The phone build uses the production-data profile explicitly; it does not use local emulators. Client Firebase configuration and generated environment outputs stay local to the build.

Validate the built app's bundle identifier, display name, signing team and app-group entitlement before installing. A Debug Flutter build on a physical iPhone needs launch through Flutter/Xcode; use Release for independent daily launches.
