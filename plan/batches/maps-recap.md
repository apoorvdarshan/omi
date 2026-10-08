# Batch: maps-recap

## Screens
- Conversation map / Places page and its cluster chooser
- Recap detail: 'Your day's journey' sheet
- Recap detail: Memories learned review sheet, blocking spinners, stats tiles

## Owned files (only these may be created/edited)
- app/lib/pages/conversations/conversation_map_page.dart
- app/lib/pages/settings/daily_summary_detail_page.dart
- app/lib/widgets/omi_map_preview.dart
- app/lib/widgets/native_static_map.dart
- app/test/mobile/native_ui/native_maps_recap_test.dart
- app/integration_test/native_maps_recap_host_test.dart

## Instructions
Common rules: Dart only. No MapKit, and native code never fetches /v1/static-map (it needs the app auth header). Coordinates are never logged. The recap owner keeps getConversationById, regenerateDailySummary and deleteDailySummary. Flag-off behaviour is unchanged (conversation_map_groups_test stays green). Uses P0 (showMemoryReviewSheet seam), P1 (activity) and P2. 1) New lib/widgets/native_static_map.dart: Future<String?> resolveNativeStaticMapFile({required List<OmiMapPin> pins, required int width, required int height, required Brightness brightness, required bool Function() current}). It goes through buildOmiStaticMapUrl and getAuthHeader via the existing CachedNetworkImageProvider path (no new client), encodes PNG at no more than 16 MB, writes getTemporaryDirectory()/omi_native_map_<timestamp>.png and returns a file URI or null. Callers delete the file on dispose, on brightness change and on session change, and delete late completions (the media_viewer_native.dart idiom). Expose normalizeOmiMapPins and buildOmiStaticMapUrl from omi_map_preview.dart if needed, without changing its Flutter rendering. 2) ConversationMapPage, behind a stateful native wrapper when iosSwiftUiEnabled: IosNativeSurface(title conversationMap, fallback classic, toolbar back, empty noConversationsYet or unknownLocation). Section 'conversation_map_preview': NativeRow('conversation_map_image', conversationMap, kind 'image', imageUri: the file, maximumValue 4) when the file exists, a couldNotLoadMap label on failure, and 'conversation_map_open' (l10n.openInMaps, symbol map) calling MapsUtil.launchMap at the first group anchor. Groups section: 'conversation_map_group_<index>' navigation rows (title conversationDisplayTitle or conversationCount(n); a locked single conversation shows l10n.conversations; symbol mappin.circle.fill or square.stack) calling _openGroup. A single group goes through updateConversation(id, day key) then ConversationDetailPage. Multiple groups open showOmiSheet with a nativeBuilder chooser of 'conversation_map_cluster_<index>' rows (title, dateTime subtitle) that pop, then open, session-fenced. Index ids are mapped only in Dart. 3) Recap: 'recap_locations_map' opens showOmiSheet with a nativeBuilder: the image row (static map file), 'recap_open_maps' (openInMaps) and timeline 'recap_location_<index>' buttons (shortName, 12-hour time range, mappin) calling launchMap. 'recap_review_memories' calls showMemoryReviewSheet(context, items: summary.memoriesLearned, source: MemoryReviewSource.dailySummaryDetail, impressionKey: summary.id or widget.summaryId, title: l10n.memories); its native rows come from the chat batch. Both showDialog(OmiSpinner) spinners use showIosNativeActivity when available, keeping the root-navigator Flutter spinner as fallback and dismissing in finally even when unmounted. Replace 'recap_stats' with 'recap_conversations_stat' (navigation to DayConversationsPage when recapDay != null), 'recap_tasks_stat' (to DayTasksPage), and labels for watching minutes and proactive moments, exactly as the classic tiles. Regenerate errors (429, 400, other) and confirmations stay as today. New string: openInMaps ('Open in Maps'), pre-landed by the integrator.

## Tests
native_maps_recap_test.dart: projection from buildConversationMapGroups for single and multi groups, both empty-state choices, locked-title substitution, pins equal to normalizeOmiMapPins, and Open in Maps calling launchMap with the first anchor (through an injected launcher seam); the static-map temp file is deleted on dispose and session change and stale fetches are discarded; the recap journey rows and launch; the activity handle is dismissed exactly once on success, error and unmount; the memories row calls showMemoryReviewSheet; the stats rows route correctly. Host (native_maps_recap_host_test.dart): search 'search_places' opens the native map; a single group opens native detail; a multi group opens the native chooser, which pops and opens; a recap with fixture locations opens the native journey sheet; the temp file is gone after close.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- M6: also project the recap loading and not-found states (daily_summary_detail_page.dart build() ~104-114 and _buildNotFound ~293-312), not only _nativeContent.
- Keep frozen DailySummaryDetailPage(summaryId:, summary:) and its {'deleted': true} pop result.
- Uses the new l10n key openInMaps (already in base). Static map PNGs are Dart-fetched temp files, cleaned on dispose/session change.
