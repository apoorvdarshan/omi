# w10-mcp-transcript-budget

- Issue: #22806 — MCP transcript reads can return double max_chars and report a clipped response as complete
- PR: #22807 — fix(mcp): charge the transcript budget for original_text
- Branch: `fix/mcp-transcript-original-text-budget` (fork `apoorvdarshan/omi`)
- Head: c09877388a (ci:full empty commit; fix commit b77f96d676)
- Base: `origin/main` e9625bcae90833cf0d19a63ef3f0e9a8aee0fc7e

What changed:
- `bounded_transcript_segments` now charges `original_text` to `max_chars` after `text`,
  truncates it to the remaining allowance, and sets `truncated` when either field is cut.
- New failure class `FC-character-budget-misses-secondary-text` in
  `.github/failure-classes/FC-character-budget-misses-secondary-text.json`.
- Regression tests: `backend/tests/unit/test_mcp_transcript_character_budget.py`.

Verified: code reading plus `python3 -m py_compile`; not run locally (compute policy),
runs in Omi CI with `ci:full`. `scripts/failure-class validate` reports only the expected
missing-artifact errors from the sparse checkout; the new definition validates cleanly on
its own. Watcher entry added to `watch.inbox`.
