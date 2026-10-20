**Product impact**

- Primary loop layer (pick one): UX-Polish
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

On the web Tasks page, `bulkDelete` awaits `Promise.all` over the selected task ids. The first rejected DELETE sends every other outcome to the catch block, which puts the whole selection back. Tasks whose DELETE succeeded are therefore restored as ghosts: the server no longer has them, but the list shows them again until a reload drops them. Each successful DELETE also invalidates the action-items cache, so that reload is usually already in flight, which makes the rows flicker back and disappear. Opening one of the restored, already-deleted tasks fails.

**To Reproduce**

1. Open Tasks in the web app with at least three tasks.
2. Enter select mode and select three tasks.
3. Make one DELETE fail (server 500, network drop, or a rate limit) while the other two succeed.
4. All three tasks reappear in the list.
5. The two whose DELETE succeeded are gone on the server; clicking them fails, and the next reload removes them again.

**Current behavior**

A partly failed bulk delete restores every selected task, including the ones the server deleted, and only surfaces the first failure.

**Expected behavior**

Only the tasks whose DELETE failed come back; tasks the server deleted stay gone, and the error is shown.

**Screenshots**

Not applicable; the list state is covered by a hook test.

**user ID (can we access the user info to validate the bug?):**

Not applicable; this reproduces from client state and a failing DELETE, with no account data needed.

**Smartphone + device (please complete the following information):**

- Device: desktop browser
- OS: any
- Browser: any
- App Version: `web/app` at `e660746cf2d92f6eca498a26627ca16c64dd5d46`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/e660746cf2d92f6eca498a26627ca16c64dd5d46/web/app/src/hooks/useActionItems.ts#L636-L654 — `Promise.all` plus a catch that runs `setItems((prev) => [...prev, ...deletedItems])` for the whole selection.
