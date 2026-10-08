# Batch: chat-structured-messages

## Screens
- Chat AI message parts inline (Markdown body, action bar, initial options, day summary, receipts) and inspector parity fix
- Chat thumbs-down 'What went wrong?' feedback sheet
- Activity steps and Activity timeline sheet
- Chart messages (bar/line)
- Structured content blocks (task, goal, capture/conversation link, memory link, question, discovery, agent run, fallback text)
- Memory review card in chat replies and the shared showMemoryReviewSheet native builder (used by recap)
- Conversation citations and evidence references
- Message attachment chips
- Quota-exceeded plans sheet and chat options sheet shells

## Owned files (only these may be created/edited)
- app/lib/pages/chat/page.dart
- app/lib/pages/chat/widgets/ai_message.dart
- app/lib/pages/chat/widgets/user_message.dart
- app/lib/pages/chat/widgets/message_action_bar.dart
- app/lib/pages/chat/widgets/chart_message_widget.dart
- app/lib/pages/chat/widgets/markdown_message_widget.dart
- app/lib/pages/chat/widgets/files_handler_widget.dart
- app/lib/pages/chat/widgets/chat_apps_drawer.dart
- app/lib/pages/chat/widgets/chat_message_plan.dart
- app/lib/pages/chat/widgets/chat_message_native.dart
- app/lib/pages/chat/widgets/message_action_commands.dart
- app/lib/pages/chat/widgets/content_blocks/chat_content_block_list.dart
- app/lib/pages/chat/widgets/content_blocks/task_card_block.dart
- app/lib/pages/chat/widgets/content_blocks/goal_link_block.dart
- app/lib/pages/chat/widgets/content_blocks/conversation_link_blocks.dart
- app/lib/pages/chat/widgets/content_blocks/memory_link_block.dart
- app/lib/pages/chat/widgets/content_blocks/question_card_block.dart
- app/lib/pages/chat/widgets/content_blocks/discovery_card_block.dart
- app/lib/pages/chat/widgets/content_blocks/agent_run_blocks.dart
- app/lib/pages/chat/widgets/content_blocks/chat_block_chrome.dart
- app/lib/widgets/components/memory_review_card.dart
- app/lib/widgets/components/memory_review_controller.dart
- app/lib/widgets/components/chat_evidence_card.dart
- app/test/mobile/native_ui/native_chat_messages_test.dart
- app/test/unit/chat_message_plan_test.dart
- app/test/widgets/memory_review_controller_test.dart
- app/test/widgets/memory_review_card_test.dart
- app/integration_test/native_chat_host_test.dart

## Instructions
Common rules: Dart only. MessageProvider, ActionItemsProvider, GoalsProvider, MemoriesProvider, ConversationProvider and the existing HTTP and launchUrl owners keep every mutation. No server id becomes a row id or payload. Any unmapped plan part throws, so the chat falls back instead of dropping content. Flag-off behaviour is unchanged, and chat_scroll_layout_test plus the existing chat and content-block tests stay green. Uses P0, P1, P2 and P5. 1) Phase 0, ship first: in _openNativeMessage pass displayOptions: provider.messages.length <= 1, replyFailure: provider.replyFailure(message), and the same onAskOmi, updateConversation, setMessageNps and onRetry wiring as the classic transcript. 2) Extract a pure ChatMessagePlan.of(message, {displayOptions, showTypingIndicator}) into chat_message_plan.dart from buildMessageWidget and ChatContentBlockList. It returns ordered parts: body or blocksReplaceBody text, citations, daySummary, initialOptions, activity, chart, actionBar, blocks, reviewCard, evidence, memoryActionReceipt. The Flutter widgets consume it with no behaviour change, and an unknown part throws. 3) chat_message_native.dart: nativeMessageRows maps each part to rows with ids 'chat_<part>_<messageId>_<index>' only. Successful messages have no tap action. Failed messages keep retry, with symbol arrow.clockwise and a title from an extracted chatReplyFailureText(l10n, failure). Delete _openNativeMessage once every part maps. 4) Body: the message_ai row gets blocks: nativeRichText(text) and options: nativeRichTextLinks(text). A link value calls launchUrl through the existing owner. Cache parsed blocks per (message id, text hash) while streaming. User messages use message_user with plainText: true. A 'Context: ...' prefix becomes a label row before the bubble, with symbol arrow.turn.down.right and 50 chars plus an ellipsis. 5) Actions: menu row 'chat_actions_<id>' (symbol ellipsis) with options {copy, helpful, not_helpful, share, ask} and a subtitle showing the current rating. Extract MessageActionCommands into message_action_commands.dart from _MessageActionBarState: copy with length-only analytics, rate with optimistic revert when setMessageNps returns false, share with its origin. Both renderers use it. Choosing the current rating toggles it back to 0, as in Flutter. not_helpful, when not selected, opens showFeedbackBottomSheet with a nativeBuilder: FeedbackBottomSheet in a native mode with reason button rows (checkmark.circle.fill or circle), a comment text row with maximumLength 500, and toolbar close plus Submit, enabled only once a reason is chosen; it returns the same (key, comment) value. ask opens showIosNativeModal(title askOmi, a text row prefilled with the message text, maximumLength = min(max(length, 10000), 262144), actions cancel and ask) and sets _selectedContext to the trimmed result. This is the documented replacement for SelectionArea's Ask Omi; the user trims the text to the substring they want. Initial options: button rows chat_starter_<i> that call _sendMessageUtil, only when the plan includes them. Day summary: a label header, a rich_text ordered list from a now-static DaySummaryWidget.splitMessage, and a menu {copy, share}. memoryAction receipt: a label with symbol brain. 6) Activity: navigation row 'chat_activity_<id>' with title = last step text (or l10n.thinking), subtitle l10n.activity, symbol from the ported _getThinkingIcon map, and imageUri = nativeImageUri(app icon) when the step has an app_id. While streaming, show one label row per step. A tap opens showIosNativeModal (a sheet) with one label per step plus a final done or thinking label; fall back to showChatActivitySheet. 7) Chart: a chart row with chartStyle bar or line and index-based x points. While streaming, a chart placeholder is a label (l10n.loading, symbol chart.bar). An empty dataset emits no row. 8) Content blocks: TaskCard is a task row calling updateActionItemState (Swift pending covers the in-flight guard), with loading and unavailable labels and hydration via ensureLoaded once per message. GoalLink is a navigation row opening a showIosNativeModal alert with the formatted progress (extract GoalLinkBlock._format). Capture and ConversationLink are navigation rows calling openChatBlockConversation, session-fenced; a false result flips the row to an unavailable label through page state. Recommended steps are rich_text bullets. MemoryLink calls showMemoryDialog. QuestionCard is a label plus option buttons with index ids calling _sendMessageUtil(preparedAnswer); once answered, only the chosen option shows, disabled. DiscoveryCard is a label plus a show more/less toggle. Agent spawn and completion are read-only labels with status symbols. Fallback text uses rich_text. 9) Memory review: extract MemoryReviewController into memory_review_controller.dart from _MemoryReviewCardState (optimistic, inFlight, failed and settledEdits state; review; saveEdit; contentOf; hydration budget; impression de-dupe). MemoryReviewCard keeps its UI on top of the controller. Native rows 'chat_review_<msgId>_<i>' are a label plus a menu {right, wrong, fix}; fix opens a guarded showIosNativeModal text row (maximumLength 10000) and calls saveEdit only on Save. Also implement the nativeBuilder inside showMemoryReviewSheet (the P0 seam) with the same rows, so maps-recap gets native review without editing this file. 10) Citations: extract openChatCitation(context, citation) from _openCitedConversation (offline error, resolve or fetch with an in-flight guard, not-found info, analytics, push detail, apply modified details) and use it for navigation rows 'chat_citation_<msgId>_<i>'. Evidence becomes label rows 'chat_evidence_<msgId>_<i>' with a symbol by kind and no action, via visibleSupplementalEvidence. 11) Files: label rows only when filesId is not empty, with symbols by extension (pdf doc.richtext, txt/md doc.plaintext, doc doc.text, xlsx tablecells, pptx rectangle.on.rectangle.angled, otherwise doc). No QuickLook. 12) _showPlansSheetOnQuotaExceeded and _openNativeChatOptions pass a nativeBuilder (PlansSheet and ChatAppsDrawer already project native surfaces). No new strings.

## Tests
Unit, chat_message_plan_test.dart: plan parity with buildMessageWidget across the fixtures from server_message_content_blocks_test and chat_content_block_parity_test (blocksReplaceBody, memories, day summary, displayOptions, follow-up exclusion); an unknown part throws. native_chat_messages_test.dart: the inspector regression (displayOptions == messages.length <= 1); unique sanitized ids for duplicate wire block ids across messages; helpful toggles 1 to 0 with a revert on false; not_helpful requires a reason (cancel means no mutation) and rejects a comment over 500; copy and share analytics carry length only; starters appear only for the first message; the task block toggle calls updateActionItemState once; a bool is rejected while the task is unresolved; a question option sends preparedAnswer; a conversation link not found flips to unavailable; a session change during a fetch does not navigate; evidence excludes conversation-source refs when citations exist; file symbols; Ask Omi sets the trimmed context. memory_review_controller_test.dart: memory_review_card_test scenarios moved onto the controller (optimistic revert, a settled edit after an id change, failed state, impression de-dupe), plus native menu options per state and the Fix modal save/cancel. Host (native_chat_host_test.dart): a real MessageProvider with fake HTTP renders rich bodies inline, a rating persists, and a content-block task toggles.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- V5: a throw during build does not trigger the IosNativeSurface fallback. Unmapped plan parts must produce an invalid projection (e.g. an explicitly invalid row) or a classic-only path, never an exception.
- C6: row ids may embed message ids that already appear in existing row ids ('chat_message_<id>'); the rule is: no secret/private text in ids, ids validated by the existing rules. Keep existing 'chat_message_*' ids.
- Links in rich message bodies go through the P5 whitelist (options) and the existing Dart URL owner.
- Chart labels use the P5 truncation helper.
- Keep frozen signature ChatPage(isPivotBottom:, autoStartVoice:, initialDraft:).
