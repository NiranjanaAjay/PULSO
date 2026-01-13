"""
Analysis Pydantic Models
Models for AI analysis requests and responses
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class RiskLevel(str, Enum):
    """Risk assessment level from AI analysis"""
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"


class AnalysisResponse(BaseModel):
    """Response model for ECG analysis"""
    analysis_id: int
    reading_id: int
    prediction: str = Field(..., description="ECG pattern analysis headline")
    confidence_score: float = Field(..., ge=0, le=1, description="AI confidence 0-1")
    risk_level: Optional[RiskLevel] = None
    recommendations: Optional[List[str]] = None
    clinical_analysis: Optional[str] = None  # Professional-level analysis
    diagnosis_summary: Optional[str] = None  # Layman-friendly explanation
    detailed_analysis: Optional[str] = None  # Structured breakdown (rhythm, rate, HRV, significance)
    summary: Optional[str] = None  # One-line summary takeaway
    created_at: datetime


class AnalysisHistoryItem(BaseModel):
    """Summarized analysis for history list"""
    analysis_id: int
    reading_id: int
    risk_level: Optional[str] = None
    confidence_score: float
    created_at: datetime


class GeminiAnalysisResult(BaseModel):
    """Internal model for Gemini API response parsing"""
    pattern_analysis: str
    heart_rate_assessment: str
    risk_level: RiskLevel
    recommendations: List[str]
    follow_up: str
    confidence: float = Field(..., ge=0, le=1)
