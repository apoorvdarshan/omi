# Batch: app-catalog-reviews

## Screens
- Ratings & reviews full list (ReviewsListPage) with star filter and owner reply
- Native app detail: reviews sheet chrome and app options sheet (keep public, manage, delete)
- Capability apps page and Category apps page

## Owned files (only these may be created/edited)
- app/lib/pages/apps/app_detail/reviews_list_page.dart
- app/lib/pages/apps/app_detail/reviews_section.dart
- app/lib/pages/apps/app_detail/native_app_detail.dart
- app/lib/pages/apps/widgets/show_app_options_sheet.dart
- app/lib/pages/apps/widgets/capability_apps_page.dart
- app/lib/pages/apps/widgets/category_apps_page.dart
- app/test/mobile/native_ui/native_app_catalog_test.dart
- app/integration_test/native_app_catalog_host_test.dart

## Instructions
These screens were missed by the scouts: the native app detail reaches Flutter-only ReviewsListPage (including the owner reply dialog) and showAppOptionsSheet, and chat and summary templates reach CapabilityAppsPage. Common rules: Dart only. AppProvider, the apps HTTP API and the existing review submit code stay the owners. Flag-off behaviour is unchanged. Uses P0, P1 (activity during reply) and P2. 1) ReviewsListPage: IosNativeSurface (fallback the current Scaffold) with toolbar back. 'reviews_filter' is a segmented or choice row {'0': all, plus '1'..'5' as starFilterLabel(n) only for star counts present} calling filterReviews. Review label rows 'review:<index>' have title username (or anonymousUser) and subtitle stars · timeago · review · owner response. For the owner, add a 'review_reply:<index>' button (reply or editReply). It opens a guarded showIosNativeModal text loop (title replyToReview, a text row with maximumLength 250 and placeholder writeYourReply, actions cancel and send) that runs the existing submit body; empty text is not sent; show showIosNativeActivity while sending; success and failure toasts are unchanged. empty is noReviewsFound. 2) native_app_detail.dart openReviews: pass nativeBuilder: (_) => RecentReviewsSection(nativePage: true, ...) (it already projects IosNativeSurface or IosNativeEdit) instead of hosting it inside the Flutter sheet scaffold; adjust reviews_section.dart sizing only if needed. 3) show_app_options_sheet.dart showAppOptionsSheet gains a nativeBuilder IosNativeSurface: toggle 'app_keep_public' (keepItemPublic) calling the existing confirm and change; navigation 'app_manage' (manageApp) calling UpdateAppPage; destructive 'app_delete' (deleteItemTitle) calling the existing _delete. 4) CapabilityAppsPage and CategoryAppsPage: IosNativeSurface (fallback the current page) with loading; failed (unableToLoadApps, retry through the existing loader); empty (noAppsInCategoryYet / checkBackLaterForNewApps); sections per category group (or a single list); and app rows '<group>_<index>' as navigation with imageUri nativeImageUri(icon), subtitle description and rating, calling AppDetailPage. Show the categoryAppCount subtitle. No new strings.

## Tests
native_app_catalog_test.dart: filter options only for present ratings; a reply sends trimmed text once, blank is rejected, cancel means no mutation; non-owners see no reply rows; the options sheet toggle requires confirm, delete requires confirm, manage routes; capability and category list states and rows route to AppDetailPage. Host (native_app_catalog_host_test.dart): native app detail opens the native reviews sheet and the full list, and an owner reply goes through a fake HTTP owner.

## Depends on
None
