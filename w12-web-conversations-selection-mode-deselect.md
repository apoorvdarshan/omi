# w12-web-conversations-selection-mode-deselect

- Issue: #22918 — Web Conversations: entering selection mode immediately re-selects the newest tile instead of closing the detail pane
- PR: #22919 — fix(web): keep the detail pane closed when entering selection mode
- Branch: `fix/web-conversations-selection-mode-deselect` (fork `apoorvdarshan/omi`)
- Head: eed8ffb6e1 (test-harness commit; ci:full empty commit 0638e94722; fix commit c00c59de61)
- Base: `origin/main` 9e8a777c9f9f2706e1bebf835bb5b141ac061c52

What changed:
- `ConversationSplitView.enterSelectionMode` / `enterSelectionModeWithId` set
  `preventAutoSelect.current = true` after clearing `selection`, and the auto-select effect
  returns early while `isSelectionMode` is active.
- Failure class: `FC-default-selection-effect-overrides-explicit-clear` (new,
  `.github/failure-classes/FC-default-selection-effect-overrides-explicit-clear.json`).
- Regression test: `web/app/src/components/conversations/__tests__/ConversationSplitView.test.tsx`
  (`closes the detail pane when entering selection mode instead of re-selecting the newest tile`).

Verified: code reading, FC definition validated with `scripts/failure-class`'s
`validate_definition` (`definition errors: none`); tests not run locally (compute
policy), run in Omi CI (`web-app-checks`) with `ci:full`. Watcher entry added.

CI: first Hygiene run failed `web-app-checks` because the new test's Select click swaps the
toolbar label through `TextSwap`, which reads `prefers-reduced-motion`; jsdom has no
`window.matchMedia`. Commit eed8ffb6e1 stubs `matchMedia` for that test file; re-run pending.

