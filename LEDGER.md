# Omi continuous fix loop — ledger (rebuilt 2026-10-19 after an external cleanup deleted the folder at ~11:51)

Goal (set 2026-10-19 ~04:27): find new Omi issues, fix, PR upstream with ci:full, delete local clones; repeat until the user clears it.
Mechanics: BRIEF.md (agents), omi-fix-batch.js / omi-find-fix.js (Workflow scripts), loop-ci-watch.sh (CI watcher, deletes worktrees when green),
classify-backend-failure.sh + rerun-blocked.sh (main-caused failures), backup-records.sh (pushes this folder to fork branch omi-loop-records).
Pacing: ~4-5 agents (session limit = fixed budget per 5-hour window).

## Loop PRs (from GitHub, 2026-10-19T06:58:00Z)
- #22251 OPEN (fixes #22250) fix(tasks): invalidate cached task lists when a suggestion is accepted
- #22255 OPEN (fixes #22254) fix(app): update an app's rating when you review it
- #22257 OPEN (fixes #22256) fix(search): keep keyword hits that spoken-word hits push off page one
- #22259 OPEN (fixes #22258) fix(web): coalesce task list reloads after deletes
- #22262 OPEN (fixes #22260) fix(desktop): stop completed and deleted tasks coming back in Tasks search
- #22264 OPEN (fixes #22263) fix(backend): re-arm a task's phone reminder when it is renamed
- #22270 OPEN (fixes #22269) fix(imports): read Zoom's GMT file-name times as UTC
- #22273 OPEN (fixes #22272) fix(memories): resume ledger history pages after the last returned row
- #22275 OPEN (fixes #22274) fix(memories): stop short-word memory searches from listing every memory
- #22277 OPEN (fixes #22276) fix(tasks): invalidate cached task lists after workstream task writes
- #22279 OPEN (fixes #22278) fix(web): make the 7-day and this-week date presets cover the whole range
- #22284 OPEN (fixes #22283) fix(web): keep Tasks list shortcuts on the rows the search shows
- #22286 OPEN (fixes #22285) fix(app): open the chat when an iOS chat-answer push is tapped
- #22289 OPEN (fixes #22287) fix(app): keep the webhook URLs when reading them fails
- #22290 OPEN (fixes #22288) fix(windows): keep yesterday's chats under Yesterday after a DST change
- #22292 OPEN (fixes #22291) fix(stt): keep provider casing in pre-recorded transcript segments
- #22294 OPEN (fixes #22293) fix(chat): give each conversation one citation number per turn
- #22296 OPEN (fixes #22295) fix(listen): never let a calendar meeting shorten the silence timeout
- #22298 OPEN (fixes #22297) fix(backend): stop capping live transcription after a fair-use restriction expires
- #22301 OPEN (fixes #22300) fix(go-sdk): report a Parakeet stream closed before ready
- #22303 OPEN (fixes #22302) fix(cli): keep on-device and exact-text hits in search-screen JSON
- #22305 OPEN (fixes #22304) fix(web): fetch starred conversations from the server for the Starred tab
- #22307 OPEN (fixes #22306) fix(app): transfer multi-file device recordings to the phone
- #22309 OPEN (fixes #22308) fix(app): keep the vocabulary list when it failed to load
- #22311 OPEN (fixes #22310) fix(app): keep pendant voice questions out of app and Mentor threads
- #22314 OPEN (fixes #22312) fix(cli): keep config load and webhook target reports the same on Windows
- #22315 OPEN (fixes #22313) fix(app): show the active memories search when the page reopens
- #22317 OPEN (fixes #22316) fix(app): keep Home unfiltered after deleting a folder
- #22320 OPEN (fixes #22319) fix(merge): complete merges of conversations that overlap in time
- #22323 OPEN (fixes #22322) fix(mcp): create a new task when a finished one has the same title
- #22326 OPEN (fixes #22325) fix(sync): keep synced transcript times on the VAD file clock
- #22329 OPEN (fixes #22328) fix(web): let Enter reopen completed tasks on the Tasks page
- #22331 OPEN (fixes #22330) fix(windows): start the daily recap at local midnight after a DST change
- #22333 OPEN (fixes #22332) fix(speaker-id): keep the casing of names detected from introductions
- #22336 OPEN (fixes #22335) fix(backend): stop the fair-use case page showing an expired restriction
- #22338 OPEN (fixes #22337) fix(app): put a webhook switch back when the server does not confirm it
- #22340 OPEN (fixes #22339) fix(speaker-id): detect introduced names that contain accented letters
- #22344 OPEN (fixes #22343) fix(desktop): report a failed screen-history search as a tool error
- #22347 OPEN (fixes #22346) fix(dart-sdk): report a Parakeet stream closed before ready
- #22349 OPEN (fixes #22348) fix(web): load a conversations filter picked while the list is loading
- #22351 OPEN (fixes #22350) fix(web): take back a conversation star the server did not save
- #22354 OPEN (fixes #22353) fix(app): keep typed vocabulary words when saving them fails
- #22356 OPEN (fixes #22355) fix(desktop): keep the vocabulary list when it failed to load
- #22361 OPEN (fixes #22360) fix(app): end a multi-file device sync as soon as it is cancelled
- #22364 OPEN (fixes #22363) fix(app): stop reporting a failed ring transfer to phone as complete
- #22367 OPEN (fixes #22366) fix(app): list the tapped memory when search opens Memories
- #22370 OPEN (fixes #22369) fix(app): stop showing a failed Limitless transfer as complete
- #22375 OPEN (fixes #22374) fix(action-items): page the idempotency lookup past deleted matches
- #22378 OPEN (fixes #22377) fix(mcp): keep get_conversations offset pages full past hidden rows
- #22380 OPEN (fixes #22379) fix(web): keep a task's completion date when reopening it fails
- #22382 OPEN (fixes #22381) fix(people): find an existing person by name regardless of case
- #22384 OPEN (fixes #22383) fix(desktop): report a failed local SQL query as a tool error
- #22387 OPEN (fixes #22386) fix(device-ts): report a Parakeet stream closed before ready
- #22392 OPEN (fixes #22391) fix(web): tell the user when moving conversations to a folder fails
- #22395 OPEN (fixes #22393) fix(dart-sdk): deliver the in-flight Whisper batch on stop
- #22396 OPEN (fixes #22394) fix(web): clear the conversations error when a cached filter is shown
- #22399 OPEN (fixes #22398) fix(app): don't drop vocabulary word removals or fail them silently
- #22401 OPEN (fixes #22400) fix(backend): refuse a custom vocabulary over 100 terms
- #22403 OPEN (fixes #22402) fix(desktop): put the vocabulary list back when saving it fails
- #22405 OPEN (fixes #22404) fix(app): keep pending device recordings when clearing synced ones
- #22407 OPEN (fixes #22406) fix(app): don't let the saved category filter hide memory search results
- #22409 OPEN (fixes #22408) fix(app): stop a load or save that outlives Developer Settings from throwing
- #22411 OPEN (fixes #22410) fix(app): cancel only the iOS sync window's own drain when it expires
- #22414 OPEN (fixes #22412) fix(app): stop silently skipping SD card transfers after a reconnect
- #22415 OPEN (fixes #22413) fix(merge): hold the created webhook until the merge can no longer roll back
- #22417 OPEN (fixes #22416) fix(app): keep a Limitless recording's id when the pendant is listed again
- #22419 OPEN (fixes #22418) fix(mcp): hide Dream duplicate captures from MCP conversation cards

## Earlier batch (Oct 15-16): 11 PRs, 9 merged (#21586 #21590 #21605 #21712 #21713 #21714 #21718 #21719 #21720), #21619 + #21706 open.
Leftover batch wf_5d8ebf62-8cd done: #22414 (SD-card, fixes #22412), #22415 (merge webhook, #22413), #22417 (Limitless id, #22416), #22419 (Dream dups, #22418), #22423 (dev API next offset, #22421).
Wave 7 batch (run wf_77a2d5d9-0a2, task woeq54irh, limit 2): people create race, vocab Omi-first cut, web home task fail, web memories error, Go whisper stop, mac settings toggles, mac GET-after-PATCH, device delete notify, memories filter persistence, sdcard timeout timer, relist start time (ring+sdcard), people-stats dream dups, Windows recap memories. Leads pool: leads-all.json (172).
#22415 ratchet fixed: baseline count 4->5 for process_conversation._emit_derived_effects submit_with_context (db4e348384).

## Loop ended (user cleared the goal, then: "complete pending", "no new pr") — 2026-10-19 evening
Final: loop 71 PRs (64 merged, 7 open); all since Oct 15: 82 PRs (73 merged, 9 open). 0 closed/rejected.
Pending work finished: #22439 review fix (transaction.set instead of create; fc7b500f79) + reply; watcher cleans its
worktree when green. Unshipped Go SDK Whisper-stop fix saved to fork branch fix/go-sdk-whisper-stop (no PR, per user).
Not started (no PRs, per user): wave-7 leads (mac settings toggles, mac GET-after-PATCH, device delete notify, memories
filter persistence, sdcard timeout timer, relist start time, people-stats dream, Windows recap memories) and wave-6
candidates whose verifiers died (offline-sync created webhook regression, Tasks Select All hidden rows, etc.).
Open PRs awaiting maintainers: #22439 #22423 #22395 #22347 #22340 #22317 #22257 #21706 #21619.

## Wave 10 (2026-10-20, OpenCode continuation)
- #22800 OPEN (fixes #22799) fix(web): make Tasks Select All use the rows the view shows
- #22804 OPEN (fixes #22803) fix(web): keep the tasks a failed bulk delete did not remove
- #22807 OPEN (fixes #22806) fix(mcp): charge the transcript budget for original_text
- Not opened: RN/Swift Parakeet stream-closed-before-ready parity gap; neither SDK has a CI workflow,
  so the regression test could not run in Omi CI. See the cursor checkpoint notes.

## Wave 11 (2026-10-20, OpenCode continuation)
- #22844 OPEN (fixes #22843) fix(mcp): index the saved task description on idempotent create
- #22848 OPEN (fixes #22847) fix(action-items): notify the sharer only when a task first completes
- #22850 OPEN (fixes #22849) fix(cli): structure unindexed and stats-error empty screen searches
