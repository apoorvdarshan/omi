## What changed and why

Fixes #22793.

`addVocabularyWords` deduped new words only against the already-saved list. The vocabulary pane splits a typed entry on commas, so typing `omi, omi` produced two identical new words, both saved. The list then showed two chips for one word, and `removeVocabularyWord` filters by value, so tapping one x deleted both. A blank entry also trimmed to `''` and was saved as a word.

The batch now keeps the first copy of each new word, skips words already stored, and drops blanks. When nothing new remains, the save is skipped as before.

## Product invariants affected

none

`scripts/pr-preflight --suggest` reports no required citation; `app/lib/providers/user_provider.dart` is not in an invariant path glob. The change only normalizes the list this call would save.

## How it was verified

- Traced on current `origin/main` (`31a07230bb`): `words.map((w) => w.trim()).where((w) => !_transcriptionVocabulary.contains(w))` keeps duplicates inside `words`, and `removeVocabularyWord` uses `where((w) => w != word)`.
- No open issue or PR covers repeated input.
- `dart format --language-version=3.0 --line-length 120` on the changed Dart files. The regression tests run in Omi CI (`flutter test`) with `ci:full`. They have not been run locally.

## Tests

`app/test/providers/user_provider_vocabulary_test.dart`:

- `saves a repeated word once and drops blank entries`: saving `['omi', 'omi', '  ', 'beta']` over `['alpha']` stores `['alpha', 'omi', 'beta']`. On `main` it stores `['alpha', 'omi', 'omi', '', 'beta']`, so the test fails.
- `saves nothing when every added word is already stored`: `['alpha', ' alpha ']` performs no save, since the padded copy trims to a stored word.

## UI evidence

UI-Evidence: none -- provider list normalization; the tests assert the saved list the chips render. The running app was not exercised locally.

## Failure class (fixes)

Failure-Class: new

## Failure-class transition narrative

New class `FC-batch-add-deduped-only-against-stored-list`.

- Violated contract: adding a batch must dedupe within the batch, not only against the stored list.
- Canonical guard: `addVocabularyWords` keeps the first occurrence of each new word; the regression test saves a repeated input and asserts one stored copy.
- Evidence: the `.where((w) => !_transcriptionVocabulary.contains(w))` filter on `origin/main`. `evidence_prs` is empty because this PR is the first instance.

🤖 Generated with [Claude Code](https://claude.com/claude-code)