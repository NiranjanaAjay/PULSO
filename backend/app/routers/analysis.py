"""
Analysis Router
Endpoints for Gemini AI-powered ECG analysis
"""
from fastapi import APIRouter, Depends, HTTPException, Request, status
from slowapi import Limiter
from slowapi.util import get_remote_address
from typing import List
from datetime import datetime

from ..utils.auth import get_current_user, CurrentUser
from ..models.analysis import AnalysisResponse, AnalysisHistoryItem
from ..services.gemini_service import GeminiService
from ..services.supabase_service import SupabaseService
from ..config import get_settings

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
settings = get_settings()


@router.post("/request/{reading_id}", response_model=AnalysisResponse)
@limiter.limit(f"{settings.rate_limit_analysis}/hour")
async def request_analysis(
    request: Request,
    reading_id: int,
    user: CurrentUser = Depends(get_current_user)
):
    """
    Request Gemini AI analysis for an ECG session
    
    This endpoint:
    1. Fetches all relevant data (ECG, questionnaire, medical history, medications)
    2. Downloads the ECG snapshot image
    3. Sends everything to Gemini for analysis
    4. Stores and returns the results
    
    Rate limited to 5 requests per hour per user.
    """
    supabase = SupabaseService()
    gemini = GeminiService()
    
    # Gather all required data
    session = await supabase.get_complete_session(reading_id, user.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ECG session not found"
        )
    
    user_profile = await supabase.get_user_profile(user.id)
    r_peaks = await supabase.get_r_peaks(reading_id)
    
    # Perform AI analysis
    try:
        result = await gemini.analyze_ecg(
            session=session,
            user_profile=user_profile,
            r_peaks=r_peaks
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"AI analysis service unavailable: {str(e)}"
        )
    
    # Save analysis to database
    analysis_id = await supabase.save_analysis(reading_id, result)
    
    return AnalysisResponse(
        analysis_id=analysis_id,
        reading_id=reading_id,
        created_at=datetime.now(),
        **result
    )


@router.get("/{reading_id}", response_model=AnalysisResponse)
async def get_analysis(
    reading_id: int,
    user: CurrentUser = Depends(get_current_user)
):
    """
    Get existing analysis results for an ECG session
    
    Returns the stored AI analysis if available.
    """
    service = SupabaseService()
    analysis = await service.get_analysis(reading_id, user.id)
    
    if not analysis:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Analysis not found for this session"
        )
    
    return analysis


@router.get("/history/list", response_model=List[AnalysisHistoryItem])
async def get_analysis_history(
    limit: int = 10,
    user: CurrentUser = Depends(get_current_user)
):
    """
    Get user's analysis history
    
    Returns a list of past analyses with summary information.
    """
    service = SupabaseService()
    history = await service.get_analysis_history(user.id, limit)
    return history
