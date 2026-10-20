**Product impact**

- Primary loop layer (pick one): Retrieval-Action
- [ ] Involves data loss, failed capture, or broken sync/trust (call this out clearly below)

**Describe the bug**

The shared MCP transcript reader, `bounded_transcript_segments`, applies `max_chars` to `text` but also returns each segment's `original_text` without charging it to the same budget. Corrected transcripts always carry `original_text` (the pre-correction speech), so a transcript read can return roughly twice the requested characters. The reader also clips `original_text` without setting `truncated`, so a caller is told a clipped transcript is complete.

The bug affects both surfaces that share the helper:

- hosted MCP tools `get_conversation_by_id` and `get_conversations_by_ids` (`backend/utils/mcp_server/handlers/conversations.py`)
- the REST compatibility endpoint `GET /v1/mcp/conversations/{id}` (`backend/routers/mcp.py`), whose `SimpleTranscriptSegment` exposes `original_text`

`max_chars` is documented as "Maximum total transcript text characters to return", and `truncated` is documented as "true only when the bounded shared reader clipped the transcript".

**To Reproduce**

1. Use a conversation with a corrected transcript segment: `text` is 5 characters and `original_text` is 20 characters.
2. Call `get_conversation_by_id` with `max_chars: 10`.
3. The response contains 5 characters of `text` and 10 characters of `original_text` (15 total), and `truncated` is `false`.

**Current behavior**

The reader slices `original_text` to the budget remaining *before* `text` is counted, then adds only `len(text)` to `used_chars`. The response can exceed `max_chars` by up to the full allowance, and clipping `original_text` alone leaves `truncated` false.

**Expected behavior**

The sum of returned `text` and `original_text` characters stays within `max_chars`, and `truncated` is true whenever either field is clipped.

**Screenshots**

Not applicable; this is API output.

**user ID (can we access the user info to validate the bug?):**

Not applicable; this reproduces from a corrected transcript and the reader inputs, with no account data needed.

**Smartphone + device (please complete the following information):**

- Device: server-side API; no client device
- OS: any
- Browser: any
- App Version: `backend` at `e9625bcae90833cf0d19a63ef3f0e9a8aee0fc7e`

**Additional context**

Cause on current `main`: https://github.com/BasedHardware/omi/blob/e9625bcae90833cf0d19a63ef3f0e9a8aee0fc7e/backend/utils/mcp_server/helpers.py#L95-L113

`item['original_text'] = str(item['original_text'])[:remaining_chars]` uses the remainder before `text`, and `used_chars += len(text)` never counts `original_text`.
