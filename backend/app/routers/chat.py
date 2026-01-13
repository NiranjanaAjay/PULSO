"""
Chat Router
API endpoints for AI chat functionality
"""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

from ..utils.auth import get_current_user, CurrentUser
from ..services.supabase_service import SupabaseService
from ..services.gemini_service import GeminiService


router = APIRouter(prefix="/chat", tags=["chat"])


class ChatMessage(BaseModel):
    """Request model for chat message"""
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = None  # Optional: specific session to discuss


class ChatResponse(BaseModel):
    """Response model for chat"""
    response: str
    intent: str
    session_ids: List[str] = []
    created_at: datetime


@router.post("/message", response_model=ChatResponse)
async def send_chat_message(
    request: ChatMessage,
    user: CurrentUser = Depends(get_current_user)
):
    """
    Send a message to the AI assistant and get a response.
    
    The AI can:
    - Answer questions about specific or recent sessions
    - Compare multiple sessions
    - Provide health recommendations
    - Explain ECG concepts in simple terms
    """
    supabase = SupabaseService()
    gemini = GeminiService()
    
    # Detect intent from the message
    intent, session_ids = await _detect_intent(request.message, request.session_id, supabase, user.id)
    
    # Gather context based on intent
    context = await _build_context(intent, session_ids, supabase, user.id)
    
    # Get user profile for personalization
    user_profile = await supabase.get_user_profile(user.id)
    
    # Generate response from Gemini
    response = await gemini.chat_with_context(
        user_message=request.message,
        context=context,
        user_profile=user_profile,
        intent=intent
    )
    
    # Save chat to history
    await supabase.save_chat_message(
        user_id=user.id,
        user_message=request.message,
        ai_response=response,
        intent=intent,
        session_ids=session_ids
    )
    
    return ChatResponse(
        response=response,
        intent=intent,
        session_ids=session_ids,
        created_at=datetime.now()
    )


@router.get("/history")
async def get_chat_history(
    limit: int = 20,
    user: CurrentUser = Depends(get_current_user)
):
    """Get recent chat history for the user"""
    supabase = SupabaseService()
    history = await supabase.get_chat_history(user.id, limit)
    return {"messages": history}


async def _detect_intent(message: str, session_id: Optional[str], supabase: SupabaseService, user_id: str) -> tuple:
    """
    Detect the intent of the user's message.
    Returns (intent_type, list of session_ids to include)
    """
    message_lower = message.lower()
    session_ids = []
    
    # Check for specific session reference
    if session_id:
        session_ids = [session_id]
        return ("session_specific", session_ids)
    
    # Check for comparison keywords
    if any(word in message_lower for word in ["compare", "comparison", "versus", "vs", "difference"]):
        # Get last 2 sessions for comparison
        sessions = await supabase.get_recent_sessions_basic(user_id, limit=2)
        session_ids = [s["id"] for s in sessions]
        return ("comparison", session_ids)
    
    # Check for trend/history keywords
    if any(word in message_lower for word in ["trend", "week", "month", "over time", "history", "progress"]):
        sessions = await supabase.get_recent_sessions_basic(user_id, limit=7)
        session_ids = [s["id"] for s in sessions]
        return ("trend_analysis", session_ids)
    
    # Check for session-related keywords
    if any(word in message_lower for word in ["last session", "recent", "my session", "today", "yesterday", "heart rate", "hrv", "ecg"]):
        sessions = await supabase.get_recent_sessions_basic(user_id, limit=1)
        session_ids = [s["id"] for s in sessions]
        return ("session_query", session_ids)
    
    # Default: general health question
    return ("general_health", [])


async def _build_context(intent: str, session_ids: List[str], supabase: SupabaseService, user_id: str) -> str:
    """Build context string based on intent and sessions"""
    
    if not session_ids:
        return ""
    
    context_parts = []
    
    for i, session_id in enumerate(session_ids):
        session = await supabase.get_complete_session(int(session_id), user_id)
        if session:
            label = f"Session {i+1}" if len(session_ids) > 1 else "Latest Session"
            context_parts.append(f"""
## {label} (ID: {session_id})
- Date: {session.get('created_at', 'Unknown')}
- Duration: {session.get('duration_seconds', 0)} seconds
- Average Heart Rate: {session.get('average_heart_rate', 0):.1f} BPM
- Max Heart Rate: {session.get('max_heart_rate', 0):.1f} BPM
- Min Heart Rate: {session.get('min_heart_rate', 0):.1f} BPM
- R-Peaks Detected: {session.get('r_peak_count', 0)}
""")
    
    return "\n".join(context_parts)
