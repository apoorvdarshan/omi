#!/bin/zsh
# Deterministic CI watcher for the Omi fix loop (no LLM tokens).
# Fix agents append "<pr> <worktree-dir-name> <branch>" lines to watch.inbox; the watcher moves them into
# watch.list (its own state) at the start of each cycle (rename = race-free). Each cycle, per PR (latest run
# per check name):
#   - all checks done, none failed, ci:full present -> if the local worktree matches the PR head and is
#     clean, delete the worktree + local branch; log to watch.done; stop watching.
#   - only backend-unit failures that main shares -> queue a re-run (main-blocked.list), keep watching.
#   - any other failure on a head not yet reported -> log to watch.failures, exit 3 after the cycle.
#   - merged/closed -> same cleanup, logged.
# Exits 0 after MAX_MIN minutes so the lead can restart it.
REC=${REC:-/Users/apoorvdarshan/omi/repair-evidence/omi-loop}
REPO=/Users/apoorvdarshan/omi/repository
LIST=$REC/watch.list; INBOX=$REC/watch.inbox; DONE=$REC/watch.done; FAIL=$REC/watch.failures; SEEN=$REC/watch.reported
MAX_MIN=${MAX_MIN:-110}; SLEEP=${SLEEP:-240}
mkdir -p $REC; touch $LIST $DONE $FAIL $SEEN
start=$(date +%s); cycle=0

cleanup() { # pr dir branch head verdict
  local pr=$1 dir=$2 br=$3 head=$4 verdict=$5
  if [ -n "$dir" ] && [ "$dir" != "-" ] && [ -d "/Users/apoorvdarshan/omi/$dir" ]; then
    local w="/Users/apoorvdarshan/omi/$dir" lh dirty
    lh=$(git -C "$w" rev-parse HEAD 2>/dev/null)
    dirty=$(git -C "$w" status --porcelain 2>/dev/null | grep -vE 'backend/\.venv|\.agent-brief/' | wc -l | tr -d ' ')
    if [ "$lh" = "$head" ] && [ "$dirty" = 0 ]; then
      git -C $REPO worktree remove --force "$w" && git -C $REPO branch -D "$br" >/dev/null 2>&1
      echo "$(date -u +%FT%TZ) #$pr $dir $br ${head:0:10} $verdict cleaned" >> $DONE
    else
      echo "$(date -u +%FT%TZ) #$pr $dir $br ${head:0:10} $verdict NOT-cleaned local=${lh:0:10} dirty=$dirty" >> $DONE
    fi
  else
    echo "$(date -u +%FT%TZ) #$pr $dir $br ${head:0:10} $verdict no-worktree" >> $DONE
  fi
}

while true; do
  newfail=0
  mkdir -p $REC; touch $LIST
  if [ -s $INBOX ]; then mv $INBOX $INBOX.$$ && cat $INBOX.$$ >> $LIST && rm -f $INBOX.$$; fi
  : > $LIST.next
  while read -r pr dir br <&3; do
    [ -z "$pr" ] && continue
    json=$(gh pr view "$pr" -R BasedHardware/omi --json state,headRefOid,labels,statusCheckRollup 2>/dev/null </dev/null)
    if [ -z "$json" ]; then echo "$pr $dir $br" >> $LIST.next; continue; fi
    state=$(print -r -- "$json" | jq -r .state)
    head=$(print -r -- "$json" | jq -r .headRefOid)
    if [ "$state" != OPEN ]; then cleanup $pr $dir $br $head "pr-$state" </dev/null; continue; fi
    read -r total pending fails full <<<"$(print -r -- "$json" | jq -r '
      ([.statusCheckRollup[] | {n:(.name // .context), s:(.status // "COMPLETED"), c:(.conclusion // .state // ""), t:(.completedAt // .startedAt // "")}]
        | group_by(.n) | map(max_by(.t))) as $c
      | "\($c|length) \($c|map(select(.s!="COMPLETED"))|length) \(($c|map(select(.c=="FAILURE" or .c=="TIMED_OUT" or .c=="STARTUP_FAILURE" or .c=="ERROR"))|map(.n|gsub(" ";"_"))|join(",")) as $f | if $f=="" then "-" else $f end) \([.labels[].name]|index("ci:full")!=null)"')"
    if [ "$total" = 0 ] || [ "$pending" != 0 ]; then echo "$pr $dir $br" >> $LIST.next; continue; fi
    if [ "$fails" != "-" ] || [ "$full" != true ]; then
      if [ "$full" != true ]; then [ "$fails" = "-" ] && fails="missing-ci:full" || fails="$fails,missing-ci:full"; fi
      if ! grep -q "^$pr $head" $SEEN; then
        echo "$pr $head" >> $SEEN
        # Backend-unit-only failures that main shares: queue a re-run instead of waking the lead.
        if [ "$full" = true ] && ! print -r -- "$fails" | tr ',' '\n' | grep -qvE '^(Backend_unit_shard_[0-9]/6|Backend_unit_suite)$' \
           && [ "$($REC/classify-backend-failure.sh $pr 2>/dev/null </dev/null | head -1)" = MAIN ]; then
          echo "$pr $br" >> $REC/main-blocked.list
          echo "$(date -u +%FT%TZ) #$pr $dir $br ${head:0:10} MAIN-BLOCKED (queued re-run): $fails" >> $FAIL
          echo "MAIN-BLOCKED #$pr ($dir): queued for re-run when main is green"
          echo "$pr $dir $br" >> $LIST.next; continue
        fi
        echo "$(date -u +%FT%TZ) #$pr $dir $br ${head:0:10} FAILED: $fails" >> $FAIL
        echo "FAILED #$pr ($dir, $br) head ${head:0:10}: $fails"
        newfail=1
      fi
      echo "$pr $dir $br" >> $LIST.next; continue
    fi
    cleanup $pr $dir $br $head green </dev/null
    echo "GREEN #$pr ($dir) cleaned/recorded"
  done 3< $LIST
  sort -u $LIST.next > $LIST.tmp; mv $LIST.tmp $LIST; rm -f $LIST.next
  [ $newfail = 1 ] && { echo "watcher: failures need attention (see $FAIL)"; exit 3; }
  [ $(( ($(date +%s) - start) / 60 )) -ge $MAX_MIN ] && { echo "watcher: time box reached; $(wc -l < $LIST | tr -d ' ') PR(s) still watched"; exit 0; }
  cycle=$((cycle+1)); [ $((cycle % 8)) = 1 ] && $REC/backup-records.sh >/dev/null 2>&1 </dev/null
  sleep $SLEEP
done
