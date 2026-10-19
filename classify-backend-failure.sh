#!/bin/zsh
# Usage: classify-backend-failure.sh <pr>
# Compares the failing backend unit tests of a PR with the failing tests of main's newest completed
# "Backend Unit Tests" run (workflow 303927837). Prints MAIN (every PR failure also fails on main),
# OURS (some failure is PR-only) or NONE, followed by the test ids.
PR=$1
SP=$(mktemp -d)
ids() { perl -pe 's/\e\[[0-9;]*[A-Za-z]//g' "$1" | sed -E 's/^[0-9TZ:.-]+ //' \
  | grep -E '^FAILED tests/| - error: ' | sed -E 's/^FAILED ([^ ]+).*/\1/; s/^ *\/home\/runner\/work\/omi\/omi\/backend\///' | sort -u; }
fetch_job() { curl -sL -H "Authorization: Bearer $(gh auth token)" "https://api.github.com/repos/BasedHardware/omi/actions/jobs/$1/logs" -o "$2"; }
: > "$SP/pr.ids"
gh pr view $PR -R BasedHardware/omi --json statusCheckRollup --jq '.statusCheckRollup[] | select((.name // "" | test("^Backend unit shard")) and .conclusion=="FAILURE") | .detailsUrl' \
  | sed -E 's#.*/job/([0-9]+).*#\1#' | while read -r j; do fetch_job $j "$SP/j.log"; ids "$SP/j.log" >> "$SP/pr.ids"; done
sort -u -o "$SP/pr.ids" "$SP/pr.ids"
rid=$(gh api "repos/BasedHardware/omi/actions/workflows/303927837/runs?branch=main&status=completed&per_page=1" --jq '.workflow_runs[0].id')
: > "$SP/main.ids"
gh api repos/BasedHardware/omi/actions/runs/$rid/jobs --jq '.jobs[] | select((.name|test("^Backend unit shard")) and .conclusion=="failure") | .id' \
  | while read -r j; do fetch_job $j "$SP/j.log"; ids "$SP/j.log" >> "$SP/main.ids"; done
sort -u -o "$SP/main.ids" "$SP/main.ids"
only=$(comm -23 "$SP/pr.ids" "$SP/main.ids")
if [ ! -s "$SP/pr.ids" ]; then echo NONE
elif [ -z "$only" ]; then echo MAIN; cat "$SP/pr.ids"
else echo OURS; echo "$only"; fi
rm -rf "${SP:?}"
