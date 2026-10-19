## What changed and why

Fixes #22435.

On web Home, ticking a task in the Currents list hides the row right away and then calls `toggleActionItemCompleted`. When that call fails (offline, a 5xx, an expired session), `useHomeTasks` puts the row back and only logs to the console. The task looks completed, then reappears a moment later with nothing saying why. The Tasks page handles the same failure by setting its error (`useActionItems.toggleComplete` calls `setError(...)`), and `TaskHub` shows that error in a banner.

The fix:
- `useHomeTasks` keeps the failure in a new `completeError`: the error's message, or `Failed to complete task` when the rejection isn't an `Error`. The next tick clears it.
- `HomePage` shows `completeError` under the Currents list as a `role="alert"` line, styled like the Goals error further down the same page.
- `completeError` is separate from `error` on purpose. `HomeTaskList` treats `error` as "the list never loaded" and replaces the rows with "Could not load tasks.", which would hide the task that just came back.

## Product invariants affected

none

The changed files fall only under INV-UI-1's whole-tree `web/**` glob, which needs no citation for routine UI changes. No colours change.

## How it was verified

- Traced the path on current `origin/main` (`70f9bace79`). `HomeTaskList` calls `onComplete`, which is `useHomeTasks().complete`. That adds the id to `completedIds` (row hidden) and awaits `toggleActionItemCompleted(id, true)`. On rejection it only calls `console.error` and removes the id again (row back). `UseHomeTasksReturn` had no field for the failure and `HomePage` rendered nothing for it. `toggleActionItemCompleted` rejects on any non-2xx response (`ApiHttpError`) and on network errors (`fetchWithAuthResponse`).
- Compared with the Tasks page, which reverts the same toggle and sets `error` to `err.message` (falling back to `Failed to update task`) for `TaskHub` to show.
- Checked by hand only, under this machine's compute policy: I read the changed code against the hook and testing-library APIs it calls, and kept lines within web/app's Prettier width (90).
- I didn't run vitest or tsc locally. The new tests are written to fail without the fix. They and `web-app-checks` (`bun run check`: typecheck plus vitest) run in Omi CI with `ci:full`.

## Tests

- `web/app/src/hooks/__tests__/useHomeTasks.test.tsx`, `puts a task back and says why when completing it fails`: runs the real hook with `toggleActionItemCompleted` rejecting once with `API error: 500 Internal Server Error`. The task is back in `items` and `completeError` holds that message. A later tick that saves removes its own row and clears the message. On `main` the hook reports no failure at all, so the `completeError` assertions fail.
- `web/app/src/components/home/__tests__/HomePage.test.tsx`, `says why a ticked task came back when completing it failed`: renders the real `HomePage` with the hook reporting a failed tick. The Currents region shows the message as an alert next to the restored task. On `main` there is no alert. `shows no failure while every tick has saved` checks that nothing is shown otherwise.

## UI evidence

UI-Evidence: none -- no browser session under this machine's compute policy; the change adds one conditional line of error text under Home's task list and nothing else moves, and the HomePage component test renders it

## Failure class (fixes)

Failure-Class: FC-unmounted-feedback-channel

That class's contract is the one broken here: a failed mutation must tell the user why it failed through a channel that is actually rendered. The failed tick's only report was `console.error`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
