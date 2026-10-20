## What changed and why

Fixes #22772.

`GET /v2/apps` (`backend/routers/apps.py`) defaults to `include_reviews=False` and calls `get_approved_available_apps(include_reviews=include_reviews)`. When `include_reviews=False`, `get_approved_available_apps` populates `installs` on every `App` from `get_apps_installs_count`, but skips loading reviews, leaving `rating_avg=0`, `rating_count=0`, and `score=None`. Every section in `GET /v2/apps` (except `popular`, which uses `sort_apps_by_installs_only`) and the `capability` / `category` filtered views then sort apps using `sort_apps_by_installs`.

In `sort_apps_by_installs` (`backend/utils/apps.py`), `compute_app_score(app)` multiplies `((rating_avg / 5) ** 2) * log(1 + rating_count) * sqrt(log(1 + installs))`, which evaluates to `0.0` whenever `rating_avg` or `rating_count` is `0`. Because `sort_apps_by_installs` sorted solely by `key=lambda a: a.score or 0`, every app received key `0.0` on the default `GET /v2/apps` path (and every unreviewed app received key `0.0` even when `include_reviews=True`), so Python's stable Timsort preserved Firestore document-ID order (oldest ULID first) instead of ranking by `installs`.

The fix updates `sort_apps_by_installs` to break `score` ties by `max(0, a.installs or 0)` descending:
`sorted(apps, key=lambda a: (a.score or 0, max(0, a.installs or 0)), reverse=True)`.

## Product invariants affected

none

## How it was verified

- Traced `GET /v2/apps` (`backend/routers/apps.py:526-615`) and `get_approved_available_apps` / `compute_app_score` / `sort_apps_by_installs` (`backend/utils/apps.py:261-280, 513-568, 1160-1170, 1278-1329`) on current `origin/main` (`31a07230bb`). Confirmed that `include_reviews` defaults to `False` on `GET /v2/apps`, `compute_app_score` returns `0.0` when `rating_avg` or `rating_count` is `0`, and `sort_apps_by_installs` previously sorted only by `a.score or 0`.
- Checked all callers of `sort_apps_by_installs` across `backend/utils/apps.py` and `backend/routers/apps.py` (`get_apps_v2`, `group_apps_by_capability`, and `group_capability_apps_by_category`) and existing `backend/tests/unit/test_apps*.py` suites to ensure no callers or tests rely on zero-score ties remaining in storage order.
- Local checks only (per compute policy on this machine): `scripts/backend-python-format --check`, `python3 -m py_compile` on the changed Python files, and `scripts/failure-class validate --pr-body-file`. The new regression tests were written to fail without the fix and run in Omi CI (`ci:full`).

## Tests

- `backend/tests/unit/test_apps_catalog_ranking_without_reviews.py`:
  - `test_approved_available_apps_without_reviews_ranks_by_installs_in_sort_apps_by_installs` (`from_db` and `from_redis_cache`): exercises `get_approved_available_apps(include_reviews=False)` followed by `sort_apps_by_installs` and asserts apps are ordered by `installs` descending (`['02MID_HIGH', '03NEW_MED', '01OLD_LOW']`) rather than Firestore document-ID order when `score` is `0.0`.
  - `test_v2_apps_default_without_reviews_orders_groups_and_filters_by_installs`: exercises `routers.apps.get_apps_v2` with default `include_reviews=False` across the grouped response, `capability='chat'`, and `category='productivity-and-organization'` and asserts each orders apps by `installs` descending.
  - `test_sort_apps_by_installs_keeps_positive_score_priority_and_breaks_ties_by_installs`: verifies that reviewed apps with positive `score` still outrank unreviewed apps (`score == 0.0`), unreviewed/tied apps break ties by `installs` descending, and negative `installs` values are clamped at `0`.

## UI evidence

UI-Evidence: none -- backend-only ranking fix in `backend/utils/apps.py`.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-ranking-key-zeroed-when-optional-enrichment-skipped` (`.github/failure-classes/FC-ranking-key-zeroed-when-optional-enrichment-skipped.json`):
- **Violated contract:** A ranking key that multiplies an always-hydrated signal by an optional enrichment signal collapses to zero for every record whenever the caller skips that optional enrichment (or when a record lacks it), silently falling back to storage iteration order instead of the hydrated popularity signal.
- **Canonical guard:** `backend/tests/unit/test_apps_catalog_ranking_without_reviews.py`, which drives `get_approved_available_apps(include_reviews=False)`, `sort_apps_by_installs`, and `GET /v2/apps` with reviews omitted and asserts descending install order.
- **Supporting evidence:** `GET /v2/apps` defaults to `include_reviews=False` while `sort_apps_by_installs` sorted solely by `compute_app_score(app)`. `evidence_prs` is `[]` as this PR introduces the class alongside its first fix.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
