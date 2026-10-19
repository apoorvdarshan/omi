# w7-people-create-race

- Issue: https://github.com/BasedHardware/omi/issues/22438
- PR: https://github.com/BasedHardware/omi/pull/22439 (open, labelled `ci:full`, registered in `watch.inbox`)
- Branch: `fix/people-create-race` on fork `apoorvdarshan/omi`
- Worktree: `/Users/apoorvdarshan/omi/w7-people-create-race` (sparse, left for the watcher to delete)
- Base: origin/main `70f9bace79ace710d231dcdfe40a9e53df2518f6`
- Fix commit: `59ed142f29`; head (empty `ci: run with ci:full`): `df9e9e3c1d16d9b418d8fe2bca6417e942c1caae`
- Failure-Class: new, `FC-get-or-create-lookup-outside-create-transaction` (one new definition file)

## Bug

`POST /v1/users/people` (`get_or_create_person`, backend/routers/users.py ~615-635) ran `get_person_by_name`, a plain `name ==` query, then `create_person` (`document(uuid4).set`) in a separate write. Two overlapping requests for a new name both miss the lookup and each create a person.

## Fix

- `backend/database/people.py`: new `get_or_create_person_by_name(uid, data, *, firestore_client=None)`. It reads every same-name person with a `name ==` query inside a `@firestore.transactional` body. It skips dismissed people and returns the first active match, projected like the lookup. Otherwise it calls `transaction.create(...)`. It runs under `run_with_transaction_contention_retry`, the same primitive `action_items` uses for idempotency-key dedupe. The read has no limit, so dismissed namesakes can't hide the active person (the #22374 lesson).
- `backend/routers/users.py`: the create step calls `people_db.get_or_create_person_by_name`. The lookup is unchanged and stays the fast path. The file's line count is unchanged (2715), so the line-count ratchet is not triggered.
- `backend/tests/support/firestore_query_driver_registry.py`: the `DriverEntry` the query-shape guard requires. The shape is a single `name ==` equality on `people`, the same as `find_person_by_name`, so it needs no index.
- `backend/tests/unit/test_people_get_or_create.py`: four tests on a `StrictFirestore` subclass. The strict transaction (read-before-write, create-only) is kept, and the test adds the `name ==` query the fixture doesn't model. The route race test fails on main: the patched unguarded `create_person` returns a second person.
- `.github/failure-classes/FC-get-or-create-lookup-outside-create-transaction.json`.
- Away from #22382's lines (it only edits `find_person_by_name` in person_aliases.py). Mentioned in the PR body.

## Verified (locally, no test runs per compute policy)

- Bug traced on origin/main. Duplicate check: no issue or PR covers the race. The open people PRs (#21506, #21789, #21922, #21963, #22382) touch other lines.
- `scripts/backend-python-format --check` on the 4 changed .py files: clean. `py_compile`: ok.
- `scripts/failure-class validate --base origin/main --head HEAD`: declaration `new`. The only errors are missing artifacts outside the sparse checkout. None are on the new class.
- Checked the tests that import `routers.users` under module stubs (`test_lock_bypass_fixes`, `test_users_error_sanitization`, `test_users_webhook_url_validation`, `test_daily_summary_regenerate_input_bound`, `test_free_quota_gate_wiring`). The new `database.people` import still resolves under their AutoMock/finder stubs.
- `database/people.py` is in pyright strict scope. The new code mirrors `set_person_pinned`'s typed pattern. Unknown types only come from the untyped SDK/projection boundary, which the config treats as warnings. Pyright was not run locally.
- Not run locally: pytest, pyright. Both run in Omi CI with ci:full.

## Leads

- backend/utils/speaker_tag_prompts/service.py:617-624 `_resolve_person`: the same non-atomic lookup-then-create for a typed tag-card name. A double submit creates two people. Could reuse `people_db.get_or_create_person_by_name`. Its tests patch `users_db.create_person`.
- backend/routers/listen/transcripts.py:1566-1582: a live explicit introduction does the same non-atomic get-or-create. Two concurrent sessions hearing "My name is X" create two people.
