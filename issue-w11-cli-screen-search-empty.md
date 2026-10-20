**Product impact**

- Primary loop layer (pick one): Docs-Tooling
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

In `sdks/python-cli/omi_cli/commands/local.py`, `_normalize_screen_search` only recognizes two of macOS Desktop's four empty-result strings from `ChatToolExecutor.emptySemanticSearchMessage`:

- `"No matching screen-history results..."` (`stats.indexed > 0`)
- `"No screen history is available..."` (`stats.total == 0`)

It does not match the other two empty-result strings that `emptySemanticSearchMessage` (`desktop/macos/Desktop/Sources/Providers/ChatToolExecutor.swift:1990-2025`) produces:

- `"Omi has <N> screenshot(s), but they are not ready to search yet..."` (`stats.indexed == 0`)
- `"No screenshots found matching \"<query>\" in the last <days> day(s). Local status could not be read: ..."` (when `RewindDatabase.shared.getStats()` throws)

When Desktop returns either of those two messages, `omi --json local search-screen` falls through the hit-line parser and emits `{"text": result, "query": ..., "days": ..., "app_filter": ..., "limit": ...}` without `"results": []`, `"reason"`, or `"suggestions"`.

**To Reproduce**

1. Run `omi --json local search-screen "Discord"` against a Mac where screenshots have been captured (`stats.total > 0`) but none are indexed yet (`stats.indexed == 0`).
2. Desktop returns `"Omi has 12 screenshot(s), but they are not ready to search yet. Use get_work_context for recent work, or SQL only for counts and exact structured checks."`
3. The CLI JSON output omits `"results": []`, `"reason"`, and `"suggestions"`, returning `"text"` instead.

**Current behavior**

`_normalize_screen_search` only treats `"No matching screen-history results"` and `"No screen history is available"` as structured empty results.

**Expected behavior**

All four empty-search messages returned by `ChatToolExecutor.emptySemanticSearchMessage` produce the structured empty-result JSON shape (`"results": []`, `"reason"`, `"suggestions"`, plus `"exact_fallback"`).

**Screenshots**

Not applicable; CLI `--json` output.

**user ID (can we access the user info to validate the bug?):**

Not applicable; reproduces deterministically in unit tests without account data.

**Smartphone + device (please complete the following information):**

- Device: macOS / CLI
- OS: macOS / any
- Browser: n/a
- App Version: `sdks/python-cli` at `5098bbc6eab52a955f0b043b5bedd013ea3c5851`

**Additional context**

- Producer on `main`: https://github.com/BasedHardware/omi/blob/5098bbc6eab52a955f0b043b5bedd013ea3c5851/desktop/macos/Desktop/Sources/Providers/ChatToolExecutor.swift#L1990-L2025
- Consumer on `main`: https://github.com/BasedHardware/omi/blob/5098bbc6eab52a955f0b043b5bedd013ea3c5851/sdks/python-cli/omi_cli/commands/local.py#L382-L398
