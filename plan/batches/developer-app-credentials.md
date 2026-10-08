# Batch: developer-app-credentials

## Screens
- App owner API keys (Developer API for one app) with one-time reveal
- Settings > Developer > Developer API keys page, create sheet and one-time key
- Settings > Developer > MCP page (keys, Claude Code config, Claude Desktop, server/OAuth details), create dialog and one-time key
- Developer debug-log file chooser

## Owned files (only these may be created/edited)
- app/lib/pages/apps/widgets/api_keys_widget.dart
- app/lib/pages/apps/widgets/api_keys_native.dart
- app/lib/pages/apps/widgets/native_app_owner_form.dart
- app/lib/pages/apps/update_app.dart
- app/lib/pages/settings/developer.dart
- app/lib/pages/settings/developer_native.dart
- app/lib/pages/settings/developer_api_keys_page.dart
- app/lib/pages/settings/developer_mcp_page.dart
- app/lib/pages/settings/developer_mcp_section.dart
- app/lib/pages/settings/widgets/developer_api_keys_section.dart
- app/lib/pages/settings/widgets/create_dev_api_key_sheet.dart
- app/lib/pages/settings/widgets/dev_api_key_created_dialog.dart
- app/lib/pages/settings/widgets/dev_api_key_list_item.dart
- app/lib/pages/settings/widgets/create_mcp_api_key_dialog.dart
- app/lib/pages/settings/widgets/mcp_api_key_created_dialog.dart
- app/lib/pages/settings/widgets/mcp_api_key_list_item.dart
- app/test/mobile/native_ui/native_credentials_test.dart
- app/integration_test/native_credentials_host_test.dart

## Instructions
Common rules: Dart only. Credentials cross the bridge only in the one-time sensitive sheet (P3), after an explicit Create. List rows carry only metadata (name, prefix + '***', date, scope summary). Copying always goes through OmiClipboard. Do not edit AddAppProvider, DevApiKeyProvider, McpProvider or backend/http/api/apps.dart; their default-build fixes are a separate follow-up. Fence at the presentation layer: capture AuthService.captureSessionSnapshot() before each create and present nothing if it is no longer current. Uses P0, P1, P2 and P3. 1) App owner keys: new api_keys_native.dart. The native_app_owner_form.dart 'owner_api_keys' row pushes a route whose body is IosNativeSurface(title developerApi, fallback the current Scaffold + ApiKeysWidget, loading, empty noApiKeysYet, onRefresh loadApiKeys(appId)). Toolbar: back; 'app_keys_info' (info.circle) calling showOmiAlert(omiApiKeys, apiKeysDescription, gotIt); 'app_keys_create' (plus, enabled when not creating or loading). Rows are NativeRow('app_api_key:<index>', label, kind 'menu', subtitle the createdAt date, symbol key, options {'revoke': revokeKey}, enabled when not deleting), calling showOmiConfirm and then the existing _deleteApiKey. Scope the list to this app: keep a page-local loadedFor = appId and project keys only after a load for this appId completed under the current session snapshot. On a successful create, call showIosNativeSecretSheet(title createAKey, message yourNewKey, warning pleaseCopyKeyNow + willNotSeeAgain, secretLabel apiKey, copyLabel copyToClipboard, doneLabel done, onCopy OmiClipboard.copy(what: apiKey), showClassic the existing _showNewKeyDialog), then null out _newKey. update_app.dart only adapts the offstage mount if needed. 2) Developer API: new developer_api_keys_page.dart keeps ChangeNotifierProvider(create: DevApiKeyProvider()..fetchKeys()) and returns IosNativeSurface (fallback the current section Scaffold) with loading = isLoading && keys.isEmpty, failed = error != null && keys.isEmpty, onRefresh fetchKeys(force: true) and empty noApiKeys. Toolbar: back, 'dev_keys_create' (plus). Rows: a docs row (launchUrl plus the existing analytics); 'dev_key:<index>' labels with subtitle '<prefix>*** · date · <scope summary>' from an extracted pure devKeyScopeSummary (shared with the Flutter chips); a revoke destructive button or menu calling the existing confirm then deleteKey. Key ids, names and prefixes that fail validation fall back. developer_native.dart routes 'developer_api_keys' to this page. CreateDevApiKeySheet.show gains nativeBuilder CreateDevApiKeySheet(native: true): a name text row (maximumLength 100); preset buttons (checkmark.circle.fill or circle); per-resource toggles 'dev_key_scope:<resource>:<read|write>' from the fixed allowlist; the permissionsInfoNote footer; toolbar cancel and create (enabled when the trimmed name is not empty && !_isCreating); a dirty guard; scopes null when none are selected. DevApiKeyCreatedSheet.show uses showIosNativeSecretSheet (apiKeyCreated, key name, saveKeyWarning, copyKey) with showClassic = the existing sheet. 3) MCP: new developer_mcp_page.dart (fallback the DeveloperMcpSection Scaffold), routed from 'developer_mcp_keys'. Toolbar: back, docs, create. Sections: key rows plus revoke; 'mcp_config_json' rich_text with one code block hostedMcpConfigJson(url), plus 'mcp_copy_config'; the desktop setup label plus a URL copy; a server URL copy; the auth-header template label; the OAuth label; a client ID copy; the client secret hint. Create uses a guarded showIosNativeModal text loop (name, maximumLength 100, re-presented with a validation label when blank) and shows showIosNativeActivity while McpProvider.createKey runs. The one-time key uses showIosNativeSecretSheet (keyCreated, keyCreatedMessage, keyWord). 4) developer.dart _shareLogs: with 2 or more files, use a showIosNativeModal alert with 'log_file_<index>' actions (index into the list captured at open) plus cancel; null falls back to the existing sheet. The share sheet keeps its origin. No new strings.

## Tests
native_credentials_test.dart: list projections never contain a secret and use index ids; the revoke menu accepts only 'revoke'; app keys are projected only for the current appId and session; create, then a session change, presents nothing; the secret sheet shows the key exactly once, and its showClassic path runs when unsupported; scope toggles and presets mutate only the allowlisted map; createKey receives null scopes when none; the MCP name loop rejects blank names without calling createKey; config copy rows copy the exact strings; the log chooser maps index to File. Host (native_credentials_host_test.dart) with the hermetic backend fake: GET, POST and DELETE /v1/apps/{id}/keys counts; Create shows the sensitive sheet whose projection contains the secret once; Done disposes it so the snapshot no longer contains the key; revoke requires confirm and issues one DELETE; dev and MCP create, reveal and revoke flows; sign-out clears the projections.

## Depends on
None

## Critic addendum (authoritative; supersedes the batch spec where they conflict)
- Frozen ids checked by host tests: owner_name, owner_save, developer_conversation:url, developer_save.
- Copying a secret goes only through OmiClipboard (the P3 secret row has no system text selection).
- P1 activity overlay must be dismissed before awaiting showIosNativeSecretSheet or any route (MCP create → secret sheet).
