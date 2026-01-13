"""
Supabase Service
Database operations for ECG sessions, users, and analysis
"""
from typing import Optional, List, Dict, Any
from datetime import datetime

from ..database import get_supabase
from ..models.ecg import QuestionnaireCreate, QuestionnaireResponse, ECGSessionResponse
from ..models.user import UserProfile, MedicalHistory, Medication, MedicationCreate
from ..models.analysis import AnalysisResponse, AnalysisHistoryItem


class SupabaseService:
    """Service for Supabase database operations"""
    
    def __init__(self):
        self.client = get_supabase()
    
    # ==================== Questionnaire Operations ====================
    
    async def save_questionnaire(
        self, 
        user_id: str, 
        data: QuestionnaireCreate
    ) -> Optional[QuestionnaireResponse]:
        """Save a session questionnaire"""
        try:
            result = self.client.table("session_questionnaires").insert({
                "reading_id": data.reading_id,
                "user_id": user_id,
                "caffeine_consumed": data.caffeine_consumed,
                "nicotine_consumed": data.nicotine_consumed,
                "activity_level": data.activity_level.value,
                "stress_score": data.stress_score,
                "time_of_day": data.time_of_day.value,
                "additional_symptoms": data.additional_symptoms,
            }).execute()
            
            if result.data:
                return QuestionnaireResponse(**result.data[0])
            return None
        except Exception as e:
            print(f"Error saving questionnaire: {e}")
            return None
    
    async def get_questionnaire(self, reading_id: int) -> Optional[Dict]:
        """Get questionnaire for a reading"""
        try:
            result = self.client.table("session_questionnaires") \
                .select("*") \
                .eq("reading_id", reading_id) \
                .single() \
                .execute()
            return result.data if result.data else None
        except:
            return None
    
    # ==================== ECG Session Operations ====================
    
    async def update_ecg_image_url(self, reading_id: int, url: str) -> bool:
        """Update the ECG image URL for a reading"""
        try:
            self.client.table("ecg_readings") \
                .update({"ecg_image_url": url}) \
                .eq("reading_id", reading_id) \
                .execute()
            return True
        except Exception as e:
            print(f"Error updating image URL: {e}")
            return False
    
    async def get_complete_session(
        self, 
        reading_id: int, 
        user_id: str
    ) -> Optional[Dict]:
        """Get complete ECG session with questionnaire"""
        try:
            # Get ECG reading
            reading = self.client.table("ecg_readings") \
                .select("*") \
                .eq("reading_id", reading_id) \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            
            if not reading.data:
                return None
            
            session = reading.data
            
            # Get questionnaire
            questionnaire = await self.get_questionnaire(reading_id)
            if questionnaire:
                session["questionnaire"] = questionnaire
            
            return session
        except Exception as e:
            print(f"Error getting session: {e}")
            return None
    
    async def get_user_sessions(
        self, 
        user_id: str, 
        limit: int = 10, 
        offset: int = 0
    ) -> List[Dict]:
        """Get user's ECG sessions"""
        try:
            result = self.client.table("ecg_readings") \
                .select("*") \
                .eq("user_id", user_id) \
                .order("timestamp", desc=True) \
                .range(offset, offset + limit - 1) \
                .execute()
            return result.data or []
        except:
            return []
    
    async def get_r_peaks(self, reading_id: int) -> List[Dict]:
        """Get R-peaks for a reading"""
        try:
            result = self.client.table("ecg_r_peaks") \
                .select("*") \
                .eq("reading_id", reading_id) \
                .order("sample_index") \
                .execute()
            return result.data or []
        except:
            return []
    
    # ==================== User Profile Operations ====================
    
    async def get_user_profile(self, user_id: str) -> Optional[UserProfile]:
        """Get complete user profile with medical history and medications"""
        try:
            # Get user
            user_result = self.client.table("users") \
                .select("*") \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            
            if not user_result.data:
                return None
            
            user = user_result.data
            
            # Get medical history
            med_history = None
            try:
                med_result = self.client.table("medical_history") \
                    .select("*") \
                    .eq("user_id", user_id) \
                    .single() \
                    .execute()
                if med_result.data:
                    med_history = MedicalHistory(**med_result.data)
            except:
                pass
            
            # Get medications
            medications = await self.get_medications(user_id, active_only=True)
            
            return UserProfile(
                user_id=user["user_id"],
                name=user.get("name"),
                age=user.get("age"),
                medical_history=med_history,
                medications=medications
            )
        except Exception as e:
            print(f"Error getting user profile: {e}")
            return None
    
    async def get_medications(
        self, 
        user_id: str, 
        active_only: bool = True
    ) -> List[Medication]:
        """Get user's medications"""
        try:
            query = self.client.table("medications") \
                .select("*") \
                .eq("user_id", user_id)
            
            if active_only:
                query = query.eq("is_active", True)
            
            result = query.order("created_at", desc=True).execute()
            
            return [Medication(**m) for m in (result.data or [])]
        except:
            return []
    
    async def add_medication(
        self, 
        user_id: str, 
        data: MedicationCreate
    ) -> Optional[Medication]:
        """Add a new medication"""
        try:
            result = self.client.table("medications").insert({
                "user_id": user_id,
                "medication_name": data.medication_name,
                "dosage": data.dosage,
                "frequency": data.frequency,
                "start_date": str(data.start_date) if data.start_date else None,
                "notes": data.notes,
                "is_active": True,
            }).execute()
            
            if result.data:
                return Medication(**result.data[0])
            return None
        except Exception as e:
            print(f"Error adding medication: {e}")
            return None
    
    async def deactivate_medication(
        self, 
        medication_id: str, 
        user_id: str
    ) -> bool:
        """Deactivate a medication (soft delete)"""
        try:
            result = self.client.table("medications") \
                .update({"is_active": False}) \
                .eq("medication_id", medication_id) \
                .eq("user_id", user_id) \
                .execute()
            return bool(result.data)
        except:
            return False
    
    # ==================== Analysis Operations ====================
    
    async def save_analysis(self, reading_id: int, result: Dict) -> int:
        """Save AI analysis results"""
        try:
            # Convert recommendations list to JSON string if present
            recommendations = result.get("recommendations", [])
            if isinstance(recommendations, list):
                import json
                recommendations = json.dumps(recommendations)
            
            data = {
                "reading_id": reading_id,
                "prediction": result.get("prediction", ""),
                "confidence_score": result.get("confidence_score", 0.0),
                "risk_level": result.get("risk_level", "low"),
                "recommendations": recommendations,
                "clinical_analysis": result.get("clinical_analysis", ""),
                "diagnosis_summary": result.get("diagnosis_summary", ""),
                "detailed_analysis": result.get("detailed_analysis", ""),
                "summary": result.get("summary", ""),
            }
            
            insert_result = self.client.table("analysis") \
                .insert(data) \
                .execute()
            
            if insert_result.data:
                return insert_result.data[0]["analysis_id"]
            return 0
        except Exception as e:
            print(f"Error saving analysis: {e}")
            return 0
    
    async def get_analysis(
        self, 
        reading_id: int, 
        user_id: str
    ) -> Optional[AnalysisResponse]:
        """Get analysis for a reading"""
        try:
            # Verify user owns the reading
            reading = self.client.table("ecg_readings") \
                .select("reading_id") \
                .eq("reading_id", reading_id) \
                .eq("user_id", user_id) \
                .single() \
                .execute()
            
            if not reading.data:
                print(f"[get_analysis] Reading {reading_id} not found for user {user_id}")
                return None
            
            result = self.client.table("analysis") \
                .select("*") \
                .eq("reading_id", reading_id) \
                .order("created_at", desc=True) \
                .limit(1) \
                .single() \
                .execute()
            
            if result.data:
                # Parse recommendations from JSON if needed
                import json
                data = result.data
                if isinstance(data.get("recommendations"), str):
                    try:
                        data["recommendations"] = json.loads(data["recommendations"])
                    except:
                        data["recommendations"] = []
                return AnalysisResponse(**data)
            print(f"[get_analysis] No analysis found for reading_id {reading_id}")
            return None
        except Exception as e:
            print(f"[get_analysis] Error: {e}")
            return None
    
    async def get_analysis_history(
        self, 
        user_id: str, 
        limit: int = 10
    ) -> List[AnalysisHistoryItem]:
        """Get user's analysis history"""
        try:
            # Get user's readings first
            readings = self.client.table("ecg_readings") \
                .select("reading_id") \
                .eq("user_id", user_id) \
                .execute()
            
            if not readings.data:
                return []
            
            reading_ids = [r["reading_id"] for r in readings.data]
            
            result = self.client.table("analysis") \
                .select("*") \
                .in_("reading_id", reading_ids) \
                .order("created_at", desc=True) \
                .limit(limit) \
                .execute()
            
            return [AnalysisHistoryItem(**a) for a in (result.data or [])]
        except:
            return []
    
    # ==================== Chat Operations ====================
    
    async def save_chat_message(
        self,
        user_id: str,
        user_message: str,
        ai_response: str,
        intent: str,
        session_ids: list
    ) -> None:
        """Save a chat message to history"""
        try:
            self.client.table("chat_history").insert({
                "user_id": user_id,
                "user_message": user_message,
                "ai_response": ai_response,
                "intent": intent,
                "session_ids": session_ids
            }).execute()
        except Exception as e:
            print(f"Error saving chat: {e}")
    
    async def get_chat_history(self, user_id: str, limit: int = 20) -> list:
        """Get recent chat history for user"""
        try:
            result = self.client.table("chat_history") \
                .select("*") \
                .eq("user_id", user_id) \
                .order("created_at", desc=True) \
                .limit(limit) \
                .execute()
            return result.data or []
        except:
            return []
    
    async def get_recent_sessions_basic(self, user_id: str, limit: int = 5) -> list:
        """Get basic info about recent sessions (for chat context)"""
        try:
            result = self.client.table("ecg_readings") \
                .select("id, created_at, average_heart_rate, duration_seconds") \
                .eq("user_id", user_id) \
                .order("created_at", desc=True) \
                .limit(limit) \
                .execute()
            return result.data or []
        except:
            return []

