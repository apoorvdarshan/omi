# Batch: offline-sync

## Screens
- Offline Sync (AutoSync) info sheet and Manage Storage sheet
- Legacy Offline Sync page (SyncPage) with WAL list, filters, grouping, sync/cancel/retry/delete
- Offline sync storage sheet (legacy)
- Sync confirmations (custom STT, SD card)
- Processed conversations after sync (SyncedConversationsPage)

## Owned files (only these may be created/edited)
- app/lib/pages/conversations/auto_sync_page.dart
- app/lib/pages/conversations/auto_sync_native.dart
- app/lib/pages/conversations/sync_page.dart
- app/lib/pages/conversations/sync_native.dart
- app/lib/pages/conversations/widgets/offline_sync_storage_sheet.dart
- app/lib/pages/conversations/widgets/sync_error_card.dart
- app/lib/pages/conversations/synced_conversations_page.dart
- app/lib/pages/conversations/widgets/synced_conversation_list_item.dart
- app/lib/utils/sync_confirmation.dart
- app/test/mobile/native_ui/native_offline_sync_test.dart
- app/integration_test/native_offline_sync_host_test.dart

## Instructions
Common rules: Dart only. SyncProvider, WalService, DeviceProvider.refreshRingStorageStatus, ConnectivityProvider and reProcessConversationServer stay the owners. Only labels, counts and fractions cross the bridge. Projecting status never starts a sync. Flag-off behaviour is unchanged (auto_sync_storage_refresh_test stays green). Uses P0, P2 and P4 (swipe). 1) auto_sync_page.dart: _showInfoSheet becomes a non-alert showIosNativeModal: label rows plus numbered step rows ('1. Upload' and so on, with description subtitles) and the failure footnote; the action is done as the cancel id; null falls back to the classic sheet. Manage storage gets a showOmiSheet nativeBuilder hosting a Consumer<SyncProvider> IosNativeSurface, so counts update live: 'storage_synced' (label safelyBackedUp · N plus 'storage_clear_synced', enabled when N > 0); the same for pending; toggle 'storage_auto_remove' (days subtitle; enabling calls applySyncedCopyRetention); a destructive 'storage_clear_all'. It reuses the buildStorageClearActions closures (pop, native confirm, clear with refreshDeviceStorage, toast). 2) auto_sync_native.dart windowing: project the first 200 WAL rows, then an 'offline_more' row with onVisible that raises the window by 200. This is presentation only and keeps snapshots small during active sync. 3) SyncPage: new part sync_native.dart mirroring auto_sync_native. Toolbar: back and 'sync_manage' (ellipsis, opening the OfflineSyncStorageSheet native builder). Status section: title and subtitle labels using the same phase priority; the Sync button (internet check, then the custom-STT confirmation, then the SD-card confirmation, then syncWals) or a destructive Cancel (confirm, cancelSync, toast); an error label plus retry; a 'conversations created' navigation row to SyncedConversationsPage. Storage navigation rows to LocalStoragePage and PrivateCloudSyncPage. 'sync_filter' is segmented pending, synced or failed with counts, calling setStatusFilter. Lists: one section per source group (pending, more than one source) or per date-hour header. Rows 'sync_wal:<index>' are navigation (subtitle status · time · duration · source; tap goes to WalItemDetailPage), with options {'delete'} unless syncing and swipeTrailing ['delete'], which shows the processing-specific confirm, then deleteWal. Add progress rows ('%, KB/s, ETA') and retry or delete buttons per state, windowed at 200 with onVisible for more. 4) offline_sync_storage_sheet.dart: a nativeBuilder with the same actions and confirmations. 5) sync_confirmation.dart: confirmSyncForCustomStt and the SD-card processing confirmation use showOmiConfirm (native), keeping OmiConfirmDialog only as the fallback. 6) SyncedConversationsPage: sections updated and new; rows 'synced_conversation:<index>' (title conversationRowTitle, generic copy for locked, subtitle timestamp) whose tap calls the existing onConversationTap and opens ConversationDetailPage; a 'reprocess' option and button for updated or discarded rows, with page-level in-flight state (disabled, subtitle while running) calling reProcessConversationServer and then updateSyncedConversation. No new strings.

## Tests
native_offline_sync_test.dart: port the sync page scenarios to projection assertions (status priority per phase, filter switching, source grouping, delete confirmation copy, the window of 200 rows plus more via onVisible); each storage clear path calls refreshDeviceStorage (extending the buildStorageClearActions coverage); the retention toggle persists and applies; the sync confirmations return the native result; reprocess updates the row and disables it while in flight. Host (native_offline_sync_host_test.dart): seeded WALs with no BLE; the native SyncPage renders; the Manage Storage native sheet opens; AutoSync windowing grows on scroll.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- C5: OmiConfirmDialog.show already delegates to showOmiConfirm; do not try to keep it as a separate fallback.
- Frozen ids checked by host tests: offline_status_title, offline_download, offline_retry, offline_retention in auto_sync_native.dart.
- Keep frozen AutoSyncPage(), SyncPage(), WalItemDetailPage(wal:) constructors.
