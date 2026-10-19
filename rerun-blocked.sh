#!/bin/zsh
# Re-run CI for PRs blocked by a red main, once main's backend workflow goes green again.
# Queue file: main-blocked.list, lines "<pr> <branch>" (append any time; read when main turns green).
# Waits until the newest completed main run of the workflow (default: Backend Unit Tests 303927837),
# created after this script started, succeeds; then pushes an empty commit (same tree, parent = current
# fork head) to each queued OPEN PR branch with `git commit-tree` (no worktree needed), and empties the
# queue. Polls every 10 min, max ~7 h.
REC=/Users/apoorvdarshan/omi/repair-evidence/omi-loop
REPO=/Users/apoorvdarshan/omi/repository
WF=${1:-303927837}
Q=$REC/main-blocked.list
mkdir -p $REC; touch $Q
START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for i in $(seq 1 42); do
  c=$(gh api "repos/BasedHardware/omi/actions/workflows/$WF/runs?branch=main&status=completed&per_page=1" \
        --jq ".workflow_runs[0] | select(.created_at > \"$START\") | \"\(.conclusion) \(.head_sha[0:10])\"" 2>/dev/null)
  echo "$(date -u +%H:%M) main: ${c:-no new completed run}; queued: $(sort -u $Q | grep -c .)"
  if [ "${c%% *}" = success ]; then
    sort -u $Q > $Q.run; : > $Q
    while read -r pr br <&3; do
      [ -z "$pr" ] && continue
      state=$(gh pr view $pr -R BasedHardware/omi --json state --jq .state 2>/dev/null </dev/null)
      [ "$state" != OPEN ] && { echo "#$pr is $state, skipped"; continue; }
      git -C $REPO fetch -q fork "$br" </dev/null || { echo "#$pr fetch failed"; echo "$pr $br" >> $Q; continue; }
      head=$(git -C $REPO rev-parse FETCH_HEAD)
      new=$(git -C $REPO commit-tree "${head}^{tree}" -p "${head}" -m "ci: re-run after main's backend tests went green again" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" </dev/null)
      git -C $REPO push -q --no-verify fork "${new}:refs/heads/${br}" </dev/null && echo "#$pr re-run pushed ${new:0:10} on $br"
    done 3< $Q.run
    rm -f $Q.run
    exit 0
  fi
  sleep 600
done
echo "main still not green after ~7 h"; exit 1
