## What changed and why

Fixes #22438.

`POST /v1/users/people` is documented as idempotent by name, but it looked the name up with a plain query (`get_person_by_name`) and then wrote a new random-id person in a separate write (`create_person`). Two concurrent requests for the same new name, or a retry sent while the first is still in flight, could both miss the lookup and each create a person. The user then has two people with one name.

The create step now goes through `database.people.get_or_create_person_by_name`, which re-checks the exact name inside the Firestore transaction that writes the person:

- It reads every person with that exact name before the create, and skips dismissed people as the lookup does. The read has no limit, so dismissed namesakes can't hide the active person (the trap #22374 found in the action-item idempotency lookup).
- It runs under the shared `run_with_transaction_contention_retry`, the primitive `database/action_items.py` uses to dedupe creates by idempotency key.
- Firestore transactions are serializable ("all reads and writes within the transaction take place exactly at the commit time"), so a racing create aborts and its retry returns the person the other request created.
- A person found by the re-check is projected with `project_person_learning`, the same as the lookup's result.

The lookup is unchanged and stays the fast path, so finding an existing person still costs one query. The new code lives in the small `database/people.py`, and `routers/users.py` keeps its line count.

Related: #22382 (mine) makes the lookup in `find_person_by_name` case-insensitive. This PR doesn't touch that function or its file, and the two compose: with #22382 the lookup also finds other casings, and this transaction still guards the exact-name race.

Not changed: the "Who is this?" tag card (`utils/speaker_tag_prompts/service.py`) and live explicit introductions (`routers/listen/transcripts.py`) use the same lookup-then-create pattern. They can move to this helper in a follow-up. Existing duplicates are not merged.

## Product invariants affected

none

## How it was verified

- Traced the path on `origin/main` (`70f9bace79`). `get_or_create_person` calls `get_person_by_name`, an exact `name ==` query outside any transaction, and then `create_person`, which writes `document(uuid4)`. Nothing between the two stops a second request.
- Checked that the repository already dedupes creates with a query inside the creating transaction (`database/action_items.py`, `database/messaging.py`). Firestore documents serializable isolation for transactions.
- Index safety: the new query is a single `name ==` equality on `users/{uid}/people`, the shape `find_person_by_name` already uses. It needs no composite index, and `firestore.indexes.json` is unchanged. I added the required `DriverEntry` for `database.people.get_or_create_person_by_name` to `tests/support/firestore_query_driver_registry.py`.
- Local checks only (compute policy on this machine): `scripts/backend-python-format --check` on the four changed Python files (unchanged), `python -m py_compile` on them, and `scripts/failure-class validate` on this body.
- I didn't run pytest or pyright locally. The regression tests are written to fail without the fix. They, the Firestore query-shape guard and the type check run in Omi's CI (`ci:full`).

## Tests

`backend/tests/unit/test_people_get_or_create.py` runs the real helper and the real route. Its store is the shared `StrictFirestore` fixture, whose transaction rejects a read after the first write and a `create` on an existing id. The fixture models only id-projected, bounded queries, so the test adds the one `name ==` query this path streams in the transaction.

- `test_endpoint_returns_the_person_a_racing_request_created`: the route's lookup misses, then the racing request's person lands. That is the race in the issue. The route must return that person and create nothing. On `main` it calls the unguarded `create_person` and returns a second person, so it fails.
- `test_existing_active_person_is_returned_instead_of_a_second_one`: an active person found inside the transaction is returned and nothing is created, even behind twelve dismissed namesakes that sort first.
- `test_retried_create_returns_the_person_the_first_request_created`: the second create for a name returns the first person.
- `test_person_is_created_when_only_a_dismissed_or_differently_named_person_exists`: dismissed people, other names and other users' people don't block a create, and the stored person gets `is_user_created`.

## UI evidence

UI-Evidence: none -- backend-only change; the endpoint's response shape is unchanged.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-get-or-create-lookup-outside-create-transaction`.

- Violated contract: a get-or-create keyed on a natural key, here a person's name, must decide whether the record exists in the same transaction that creates it. A lookup committed separately lets two concurrent or overlapping retried requests both miss and each create a record.
- Canonical guard: re-check the key with a query inside the creating transaction, reads before the first write, under the shared bounded contention retry. `backend/tests/unit/test_people_get_or_create.py` pins the race through the real route on the shared `backend/tests/unit/fixtures/strict_firestore_transaction.py` transaction.
- Evidence: issue #22438 and `get_or_create_person` on `origin/main` before this change. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
