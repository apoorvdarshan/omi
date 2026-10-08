# Batch: account-billing-flows

## Screens
- Cancel subscription leave flow (reason, details, consequences)
- Delete account flow (reason, details, export, typed confirmation)
- Plans sheet downgrade and annual-switch confirmations; usage and freemium plans sheet shells
- Account name edit

## Owned files (only these may be created/edited)
- app/lib/pages/settings/widgets/cancel_subscription_sheet.dart
- app/lib/pages/settings/widgets/leave_flow_widgets.dart
- app/lib/pages/settings/delete_account.dart
- app/lib/pages/settings/widgets/plans_sheet.dart
- app/lib/pages/settings/usage_page.dart
- app/lib/widgets/freemium_switch_dialog.dart
- app/lib/pages/settings/profile.dart
- app/lib/pages/settings/change_name_widget.dart
- app/test/mobile/native_ui/native_account_billing_test.dart
- app/integration_test/native_account_billing_host_test.dart

## Instructions
Common rules: Dart only. UsageProvider (cancelUserSubscription, checkout and plan owners), the deleteAccount API, DataExport, AuthService and analytics stay the owners. Irreversible actions require Dart-computed gates. Flag-off behaviour is unchanged, as is the existing native_plan_projection_test. Uses P0, P1 and P2. 1) leave_flow_widgets.dart: add Widget nativeLeaveStep(BuildContext context, {required int step, required int stepCount, required String title, String? subtitle, required List<NativeSection> sections, List<NativeRow> toolbar, required bool canPop, required Widget fallback}). It returns IosNativeSurface(fallback: the existing LeaveFlowStepScaffold) with a header section: progress row 'leave_step' (leaveFlowStepOf(step + 1, count), value step + 1, maximumValue count) plus title and subtitle labels, and a toolbar back enabled per canPop. Keep LeaveFlowExit, PopScope and the abandon analytics. 2) Cancel subscription. Step 1: reasons 'cancel_reason:<key>' from the fixed allowlist (checkmark.circle.fill or circle) plus 'leave_continue', enabled once a reason is chosen. Step 2: text row 'cancel_details' (maximumLength 300) plus continue and skip. Step 3: the cancelBillingPeriodInfo(renewalDate) label (info.circle), 6 consequence labels, 'cancel_keep' and a destructive 'cancel_confirm' (disabled while cancelling) running the existing cancel body. 3) Delete account: the same helper with 'delete_reason:<key>' and 'delete_details'. Step 3: the 3 consequence labels; 'delete_export' (exportAllData, square.and.arrow.down, enabled when !_isDeleting && !exporting, rebuilding on DataExport.exportInProgress) calling DataExport.run; text row 'delete_confirm_word' (maximumLength 32), where Dart applies the existing letters-only uppercase filter before setting the controller and calls setState so the native field shows the sanitized value; a destructive 'delete_account' enabled only when canDelete (computed in Dart) calling _confirmDelete; 'delete_keep'. 4) plans_sheet.dart: replace the downgrade and monthly-to-annual showDialog(OmiAlertDialog) with showOmiConfirm. Downgrade: title downgradeToFreemiumTitle, message downgradeLimitationsHeading plus bullet lines, confirm downgradeAnyway, destructive. Annual: title upgradeToAnnualPlan, message importantBillingInfo plus lines, confirm confirmUpgrade. Then the existing _handleSwitchToFreePlan or _handleUpgrade runs only when confirmed. The training-data opt-in stays classic (dormant). 5) usage_page.dart _showPlansSheet and freemium_switch_dialog.dart pass a nativeBuilder hosting the same PlansSheet, so the sheet chrome is native. 6) Name: extract saveGivenName(context, name) from ChangeNameWidget (SharedPreferencesUtil.givenName, AuthService.updateGivenName, nameUpdatedSuccessfully). profile.dart's 'account_name' row uses a guarded showIosNativeModal loop: title editName, label howShouldOmiCallYou, text row (maximumLength 100, prefilled from givenName or the Firebase displayName), actions cancel and save; blank re-presents with a validation label; null falls back to the existing dialog. No new strings.

## Tests
native_account_billing_test.dart: Continue is disabled until a reason is chosen; details stay within maximumLength; confirm calls cancelUserSubscription once with reason and details; keep closes with false; back is blocked while cancelling. Delete stays disabled until the sanitized word matches; deleteAccount is called once; export is disabled while deleting. Downgrade requires confirm before _handleSwitchToFreePlan; annual requires confirm before _handleUpgrade. A blank name never saves, and a valid name saves through the extracted function. Host (native_account_billing_host_test.dart): native containment for cancel step 3 and delete step 3 with a fake UsageProvider and inert deleteAccount.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- V1: plans-sheet downgrade/annual dialogs: try showIosNativeModal first and keep the existing showDialog with PlanDialogLine content when it returns null, so flag-off/Android keep the icon/colour lines.
- C2: NativeTextRow ignores row.value while focused, so the typed-confirmation field cannot display sanitised text; validate on Dart side and keep the confirm button disabled until it matches instead of rewriting the text.
- Keep frozen UsagePage(showUpgradeDialog:).
