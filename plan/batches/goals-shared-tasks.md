# Batch: goals-shared-tasks

## Screens
- Goals page (Settings > Goals): list, inline progress, add/edit/delete
- Goal form sheet (add/edit with emoji, delete)
- Accept shared tasks sheet (deep link)

## Owned files (only these may be created/edited)
- app/lib/pages/goals/goals_page.dart
- app/lib/pages/conversations/widgets/goals_widget.dart
- app/lib/pages/action_items/widgets/goal_form_sheet.dart
- app/lib/pages/action_items/widgets/accept_shared_tasks_sheet.dart
- app/lib/core/app_shell.dart
- app/test/mobile/native_ui/native_goals_test.dart
- app/integration_test/native_goals_host_test.dart

## Instructions
Common rules: Dart only. GoalsProvider and the action_items API remain the owners. Every native screen keeps the complete Flutter screen as its fallback, and flag-off behaviour is unchanged. Uses P0, P2 and P4 (swipe). These screens were missed by the scouts: Settings 'settings_row_goals' pushes the Flutter-only GoalsPage, and the shared-tasks deep link opens a Flutter sheet. 1) goals_widget.dart: extract the GoalsWidgetState operations into top-level functions with identical behaviour: addGoal with the maximumGoalsAllowed info, editGoal, saveGoal (including emoji persistence and goalEmojiSelected analytics), the delete-with-Undo path, and saveGoalProgress / updateGoalProgressUI. The Flutter widget uses them. 2) GoalsPage: when iosSwiftUiEnabled, return IosNativeSurface(title goals, fallback the current Scaffold, loading = isLoading && goals.isEmpty, onRefresh = GoalsProvider.refresh, empty goals with an 'add goal' row). Toolbar: back and 'goals_add' (plus) calling addGoal. For each goal: NativeRow('goal:<index>', '<emoji> <title>', kind 'navigation', subtitle 'current / target' formatted as today, options {edit, delete}, swipeTrailing ['delete']), and a slider row 'goal_progress:<index>' (maximumValue target, value current clamped, subtitle the formatted progress). The slider rounds in Dart and calls saveGoalProgress through a 300 ms trailing debounce, so the final value is always saved. Map index ids to the goal list captured in the projection. 3) showGoalFormSheet gains a nativeBuilder built on IosNativeEdit (title addGoal or editGoal). Text rows: goalTitle; current and target with keyboard 'decimal'. An emoji 'choice' row appears when emojiChoices are present. The toolbar has save, enabled when valid. A destructive deleteGoal row appears when editing. isDirty is set when any field changed, and validation is the same as the Flutter form. 4) Shared tasks: in app_shell.dart _handleSharedTasksDeepLink, when iosSwiftUiEnabled && Platform.isIOS call showOmiSheet(builder: the existing sheet body, nativeBuilder: AcceptSharedTasksSheet(native: true, ...)); otherwise keep showModalBottomSheet exactly as is. Native mode shows IosNativeSurface with: a sender label; one label per task (description, due date via OmiDateFormat); toolbar close and 'shared_tasks_accept' (enabled !_isAccepting) calling the existing _acceptTasks. Feedback stays AppSnackbar, which becomes native via P2. No new strings.

## Tests
native_goals_test.dart: goal rows and progress projection; slider burst saves the final value once after the debounce; delete uses the Undo path; adding past the max shows the info feedback; form validation and dirty guard; emoji choice persists; shared-tasks native sheet accepts once and refreshes action items; app_shell uses the classic modal when the flag is off. Host (native_goals_host_test.dart): Settings > Goals opens natively with a fake GoalsProvider, and add/edit round-trips through the existing owner. goals_widget_performance_test.dart stays green.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- C3: showOmiEditSheet has no nativeBuilder; follow the ActionItemFormSheet pattern (the sheet's build returns IosNativeEdit) instead.
- C10: AcceptSharedTasksSheet already paints its own surface and OmiSheetScaffold; when used as showOmiSheet's classic builder do not add a second header.
- C7/C8: goal progress uses the new P8 'level' row kind (labelled, discrete, commit on release); clamp the value into [0, target] and omit the control (label only) when the target is <= 0 or not finite instead of producing an invalid row.
