**Product impact**

- Primary loop layer (pick one): UX-Polish
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `web/app/src/hooks/useConversations.ts`, when the filter parameters (`folderId`, `startDate`, `endDate`, `starred`) change to a filter combination that has no cache entry (`!cached`), the effect resets `offset` and `hasMore` and calls `fetchConversations(0, false)` without clearing `conversations`.

Because `ConversationSplitView` renders `ConversationGallery` whenever `dayGroups.length > 0` (and only shows `ConversationGallerySkeleton` when `isLoading && dayGroups.length === 0`), switching to an uncached folder or date keeps displaying the previous filter's conversations under the new folder or date while the request is in flight. If that first fetch fails (for example when offline or on a 5xx error), `loading` clears and the previous filter's conversations remain listed under the new folder alongside the error banner.

**To Reproduce**

1. Open Conversations in the web app and let the initial `All` (or `home` folder) list load.
2. Go offline (or make the next `GET /v1/conversations` request fail) and click a folder tab you have not opened yet.
3. The error banner appears, and `All`'s conversations stay listed under the clicked folder as if they belonged to that folder.

**Current behavior**

Switching to an uncached filter keeps the previous filter's `conversations` array in state while loading and after a failed fetch.

**Expected behavior**

Switching to an uncached filter clears `conversations` (`setConversations([])`) before starting the fetch, so the loading skeleton is shown while fetching and stale conversations from the previous filter are not shown if the fetch fails.

**Screenshots**

Not applicable; covered by a hermetic hook test.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces from client hook state without account data.

**Smartphone + device (please complete the following information):**

- Device: desktop/mobile browser
- OS: any
- Browser: any
- App Version: `web/app` at `9e8a777c9f9f2706e1bebf835bb5b141ac061c52`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/9e8a777c9f9f2706e1bebf835bb5b141ac061c52/web/app/src/hooks/useConversations.ts#L220-L225
