import base64
import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator, List, Optional, Tuple

from fastapi import HTTPException

import database.chat as chat_db
import database.notifications as notification_db
import database.users as user_db
from database.apps import record_app_usage
from models.app import App, UsageHistoryType
from models.chat import ChatSession, Message, ResponseMessage, MessageConversation
from models.notification_message import NotificationMessage
from models.transcript_segment import TranscriptSegment
from utils.apps import get_available_app_by_id
from utils.executors import db_executor, run_blocking, storage_executor, sync_executor
from utils.conversation_helpers import extract_memory_ids
from utils.conversations.factory import deserialize_conversation
from utils.chat_answer_notifications import (
    send_client_displayed_notification,
    send_client_displayed_notification_async,
)
from utils.llm.chat import initial_chat_message
from utils.llm.persona import initial_persona_chat_message
from utils.observability.fallback import record_fallback
from utils.other.storage import get_syncing_file_temporal_signed_url, schedule_syncing_temporal_file_deletion
from utils.retrieval.graph import execute_graph_chat, execute_graph_chat_stream
from utils.stt.pre_recorded import (
    postprocess_words,
    prerecorded,
    prerecorded_from_bytes,
    get_prerecorded_service,
)
from utils.stt.outcomes import (
    TranscriptionFailure,
    TranscriptionOutcome,
    empty_unexpected_failure,
    failure_from_exception,
)
from utils.stt.vad import VADAudioDecodeError, VADProcessingError, linear16_pcm_is_silent, vad_is_empty_strict
from utils.llm.usage_tracker import track_usage, set_usage_context, reset_usage_context, Features
import logging

logger = logging.getLogger(__name__)
