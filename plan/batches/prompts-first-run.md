# Batch: prompts-first-run

## Screens
- Announcement dialog
- Feature screen (paged and list modes)
- What's New changelog sheet (also from Settings)
- Upgrade available/required prompt
- AppDialog context-free alerts (e.g. app enable failure)
- Onboarding setup rating prompt
- Permissions interstitial (returning user, fresh install)
- First-launch language selection sheet

## Owned files (only these may be created/edited)
- app/lib/pages/announcements/announcement_dialog.dart
- app/lib/pages/announcements/feature_screen.dart
- app/lib/pages/announcements/changelog_sheet.dart
- app/lib/services/announcement_service.dart
- app/lib/widgets/upgrade_alert.dart
- app/lib/utils/alerts/app_dialog.dart
- app/lib/pages/onboarding/setup_page.dart
- app/lib/pages/onboarding/permissions/permissions_checker.dart
- app/lib/pages/settings/language_selection_dialog.dart
- app/test/mobile/native_ui/native_prompts_test.dart
- app/integration_test/native_prompts_host_test.dart

## Instructions
Common rules: Dart only. AnnouncementService and AnnouncementProvider (seen marking, the CTA allowlist of navigate:/route and http(s) only), Upgrader, AppProvider, LocaleProvider/HomeProvider and the onboarding owners stay authoritative. All presenters stay enqueued through PromptQueue. Flag-off behaviour is unchanged. Uses P0 (FIFO, null fallback), P1 (reasons) and P2. 1) Announcement: a native dialog route or sheet, still non-dismissible: IosNativeSurface with toolbar close giving AnnouncementOutcome.closed; a rich_text row with blocks [image (https only, otherwise dropped), heading title, text body]; 'announcement_cta' calling pop(cta) plus the existing _openAction; 'announcement_not_now'. System back gives none. Outcomes and marksSeen are unchanged. 2) FeatureScreen: a fullscreen route returning IosNativeSurface (fallback the current screen) with one section per step: rich_text with the image block, heading, and text with the highlight wrapped as bold; a video step becomes a label with symbol play.rectangle. A segmented 'feature_page' row appears when pages > 1. Toolbar: close, and 'feature_next' or 'feature_done'. 3) Changelog: IosNativeSurface with loading, failed and onRefresh from _loadChangelogs; a segmented 'changelog_version' row for 5 or fewer versions, otherwise previous and next buttons with the version label; item labels ('<icon> <title>' with the description subtitle). Auto-close when empty is unchanged. 4) upgrade_alert.dart: a nativeBuilder sheet; in required mode it is non-dismissible and Update keeps it open. Rows: title and message labels, release-note labels, 'update_now', and 'update_not_now' only when optional. 5) AppDialog.show: native-first via showIosNativeModal(alert) using the overlay context. singleButton has only acknowledge; otherwise cancel and confirm with destructive mapping. Run onConfirm on 'confirm', and onCancel only for reason 'cancel'. null falls back to the existing showDialog. 6) setup_page.dart rating prompt: showIosNativeModal(alert, dismissible false, cancelId 'not_really', actions not_really (onboardingRatingPromptNo) and support (onboardingRatingPromptYes)). Map 'support' to support, reason 'cancel' to notReally, and invalidated or unmounted to no answer. null falls back to the existing dialog. 7) PermissionsInterstitialPage: when iosSwiftUiEnabled, render OnboardingPermissionsPanel(source: widget.source, nativeContinue: () => _goHome(context)), its existing native projection, and keep classic otherwise. 8) LanguageSelectionDialog.show: a nativeBuilder sheet with the same options as choice or button rows with checkmark, applying the existing selection handler. No new strings.

## Tests
native_prompts_test.dart: announcement outcome mapping (cta, closed, notNow, none) and marksSeen; the CTA parse allowlist is untouched; non-https images are dropped; feature screen steps and paging; changelog version selection; the required upgrade cannot be dismissed; AppDialog runs callbacks per reason only; the rating maps cancel to notReally and invalidation to no answer; the interstitial continues home; language selection applies once. Host (native_prompts_host_test.dart): PromptQueue shows the announcement and then the changelog sequentially on native Home; Settings What's New opens the native changelog with fixture data.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- V2: the permissions interstitial Continue must still call requestMissingOnboardingPermissions and the permissionsInterstitialCompleted analytics before _goHome; gate on iosSwiftUiEnabled && Platform.isIOS; its fallback must be the full interstitial (logo + card), not just the panel step.
- C4: showUpdatePrompt uses showOmiSurfaceSheet (no nativeBuilder); switch it to showOmiSheet with a nativeBuilder, keeping the classic look as builder.
- M7: also project the OnboardingSetupPage checklist ('Setting up your Omi', setup_page.dart) natively, not only its rating alert.
- Announcement/feature/changelog bodies: escape server text and route links through options (P5 policy).
