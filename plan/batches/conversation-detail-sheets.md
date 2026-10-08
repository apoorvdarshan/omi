# Batch: conversation-detail-sheets

## Screens
- Conversation feedback reason sheet (summary usefulness and recording quality)
- Summary template chooser and Create custom template sheet
- Conversation visibility sheet (Private/Shared)
- Share audio progress sheet
- Share via SMS to contacts sheet
- Developer Test Prompt page

## Owned files (only these may be created/edited)
- app/lib/pages/conversation_detail/widgets/feedback_sheet.dart
- app/lib/pages/conversation_detail/widgets/summarized_apps_sheet.dart
- app/lib/pages/conversation_detail/widgets/create_template_bottom_sheet.dart
- app/lib/pages/conversation_detail/widgets/conversation_detail_header.dart
- app/lib/pages/conversation_detail/widgets/audio_download_progress_sheet.dart
- app/lib/pages/conversation_detail/widgets/share_to_contacts_sheet.dart
- app/lib/pages/conversation_detail/test_prompts.dart
- app/test/mobile/native_ui/native_detail_sheets_test.dart
- app/integration_test/native_detail_sheets_host_test.dart

## Instructions
Common rules: Dart only. Do not edit conversation_detail/page.dart or native_conversation_detail.dart; every change sits behind the existing show functions. Owners: the submitMobileFeedback path, ConversationDetailProvider, AppProvider, AudioDownloadService, FlutterContacts and url_launcher. Each sheet keeps its Flutter builder as the fallback, and flag-off behaviour is unchanged (feedback_* tests stay green). Uses P0 and P2. 1) showFeedbackReasonSheet gains a nativeBuilder: IosNativeSurface with the title for its population, toolbar 'feedback_close' (xmark). A reasons section of 'feedback_reason_<enum.name>' buttons in the fixed order. 'feedback_all_good' (hand.thumbsup). 'feedback_chat_with_us' (bubble.left.and.bubble.right) only when IntercomManager.isIntercomEnabled; it opens the messenger, submits nothing and the sheet stays open. Each reason and All good runs the existing _choose path (selection haptic, pop, onSubmit(value, reason)). Dismissal submits nothing. 2) summarized_apps_sheet.dart gains a nativeBuilder (_AppsList native mode). loading is shown only until the first load completes. Sections: suggested, other and creative. App rows 'template_app:<index>' index into the deduplicated ordered list captured in the projection (default app, last used, own apps, then A-Z). They are kind navigation, with imageUri nativeImageUri(icon), subtitle description plus the defaultLabel and lastUsedLabel badges, symbol checkmark when selected, and enabled false plus subtitle installing while installing. options {'default': setDefaultButton} replace the swipe: showOmiConfirm, then setPreferredSummarizationApp. A tap calls _handleAppTap or _handleUnavailableAppTap. Creative rows: create template, and all templates (pop plus the same routes). create_template_bottom_sheet.dart native mode: text rows name (maximumLength 100) and prompt (maximumLength 10000), a make-public toggle with its description, and a validation label re-checked in Dart (at least 3 and 10 chars). The toolbar create action is enabled when !_isCreating, with title = _statusMessage while creating. Icon rendering (PictureRecorder), upload and install stay in Dart. 3) ConversationVisibilitySheet.show gains a nativeBuilder: 'visibility_private' (lock) and 'visibility_shared' (globe) buttons with description subtitles and checkmark.circle.fill on the current one, calling the existing choose(sheetContext, target). Choosing the current value only closes. 4) AudioDownloadSheetHandle gains a nativeBuilder, keeping isDismissible false, enableDrag false and the PopScope mapping back to cancel. An AnimatedBuilder over state and progress gives: a status label; a progress row (clamped finite 0..1, percent subtitle) while downloading; success or error labels with symbols; and a destructive 'audio_download_cancel' while running, calling handle.cancel(). Close stays idempotent. 5) share_to_contacts_sheet.dart gains a nativeBuilder. The search field calls _filterContacts. States: loading, failed, and a permission empty state with 'contacts_open_settings'. Toggle rows 'contact:<index>' (title name, subtitle phone, value selected). Toolbar: close; 'contacts_clear' (count > 0); 'contacts_share' (title by count, enabled when count > 0 && !_isPreparingShare), calling the existing SMS flow. Contact data crosses only while the sheet is open. 6) TestPromptsPage: IosNativeSurface (fallback the current Scaffold) with text row 'test_prompt_input' (maximumLength 10000), toolbar back plus 'test_prompt_send' (paperplane, enabled !loading), and label 'test_prompt_result' (with ** stripped). No new strings.

## Tests
native_detail_sheets_test.dart: each feedback reason calls onSubmit(-1, reason) once and pops; All good calls (1, null); Chat with us is absent when Intercom is disabled; dismissal submits nothing. Template ordering is preserved; the default option requires confirmation; the installing lock disables the row; create validation. Visibility: the current value only pops; choosing Shared calls setConversationVisibility then shareConversationLink; a failure reverts. Audio: progress is valid for 0, 0.5 and 1, NaN is clamped, and cancel calls onCancel once. Contacts: Share is disabled at 0 and the search filters by name and phone. Test prompt sends once. Host (native_detail_sheets_host_test.dart): native detail with a fake submitFeedback; Give feedback, then a reason, gives one submission; the summary template chooser opens and reprocessConversation(appId) is called once.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- M4: you also own lib/pages/conversation_detail/widgets/summary_tab.dart and summary_tab_native.dart. Add the missing 'summarized by <app>' attribution row (opens AppDetailPage) to the native summary, matching widgets.dart ~578-610.
- C9: every nativeBuilder fallback body must be wrapped in OmiSheetScaffold so a fallback keeps title, close and padding.
