#!/bin/zsh
# Back up the loop folder (records, scripts, brief) to branch `omi-loop-records` on the fork, using a
# private index file so no worktree or checkout is touched. Restores with:
#   git -C ~/omi/repository fetch fork omi-loop-records && git -C ~/omi/repository archive FETCH_HEAD | tar -x -C ~/omi/repair-evidence/omi-loop
REC=/Users/apoorvdarshan/omi/repair-evidence/omi-loop
REPO=/Users/apoorvdarshan/omi/repository
GD=$(git -C $REPO rev-parse --git-common-dir)
IDX=$(mktemp)
rm -f "$IDX"
GIT_INDEX_FILE=$IDX git --git-dir=$GD --work-tree=$REC add -A -- . ':!*.tmp' ':!*.next' ':!*.run' >/dev/null 2>&1
tree=$(GIT_INDEX_FILE=$IDX git --git-dir=$GD write-tree)
rm -f "$IDX"
parent=$(git --git-dir=$GD ls-remote fork refs/heads/omi-loop-records 2>/dev/null | cut -f1)
if [ -n "$parent" ]; then
  git --git-dir=$GD fetch -q fork omi-loop-records 2>/dev/null
  [ "$(git --git-dir=$GD rev-parse "${parent}^{tree}" 2>/dev/null)" = "$tree" ] && { echo "backup: unchanged"; exit 0; }
  new=$(git --git-dir=$GD commit-tree "$tree" -p "$parent" -m "loop records $(date -u +%FT%TZ)")
else
  new=$(git --git-dir=$GD commit-tree "$tree" -m "loop records $(date -u +%FT%TZ)")
fi
git --git-dir=$GD push -q --no-verify fork "${new}:refs/heads/omi-loop-records" && echo "backup: pushed ${new:0:10}"
