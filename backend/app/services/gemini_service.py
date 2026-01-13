"""
Gemini AI Service
Integration with Google Gemini for ECG analysis
Using direct REST API to avoid library compatibility issues
"""
import httpx
import json
import base64
import statistics
from typing import Dict, List, Optional

from ..config import get_settings


class GeminiService:
    """Service for Gemini AI ECG analysis"""
    
    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.gemini_api_key
        self.api_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent"
    
    async def analyze_ecg(
        self,
        session: Dict,
        user_profile: Dict,
        r_peaks: List[Dict]
    ) -> Dict:
        """
        Perform AI analysis on ECG session data
        
        Args:
            session: ECG session data with questionnaire
            user_profile: User profile with medical history
            r_peaks: R-peak detection data
            
        Returns:
            Analysis result dictionary
        """
        # Download image if available
        image_data = None
        if session.get("ecg_image_url"):
            image_data = await self._download_image(session["ecg_image_url"])
        
        # Build the analysis prompt
        prompt = self._build_prompt(session, user_profile, r_peaks)
        
        # Call Gemini API via REST
        try:
            result = await self._call_gemini_api(prompt, image_data)
            return self._parse_response(result)
            
        except Exception as e:
            print(f"Gemini API error: {e}")
            return {
                "prediction": f"Analysis unavailable: {str(e)}",
                "confidence_score": 0.0,
                "risk_level": "low",
                "recommendations": ["Please try again later or consult a healthcare professional"]
            }
    
    async def _call_gemini_api(self, prompt: str, image_data: Optional[bytes] = None) -> str:
        """Call Gemini API directly via REST"""
        url = f"{self.api_url}?key={self.api_key}"
        
        # Build request body
        parts = [{"text": prompt}]
        
        if image_data:
            parts.append({
                "inline_data": {
                    "mime_type": "image/png",
                    "data": base64.b64encode(image_data).decode('utf-8')
                }
            })
        
        body = {
            "contents": [{"parts": parts}],
            "generationConfig": {
                "temperature": 0.4,
                "maxOutputTokens": 2048,
            }
        }
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                url,
                json=body,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                # Extract text from response
                candidates = data.get("candidates", [])
                if candidates:
                    content = candidates[0].get("content", {})
                    parts = content.get("parts", [])
                    if parts:
                        return parts[0].get("text", "")
                return ""
            else:
                raise Exception(f"Gemini API error: {response.status_code} - {response.text}")
    
    async def _download_image(self, url: str) -> Optional[bytes]:
        """Download image from URL"""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(url)
                if response.status_code == 200:
                    return response.content
        except Exception as e:
            print(f"Error downloading image: {e}")
        return None
    
    def _build_prompt(
        self, 
        session: Dict, 
        profile: Dict, 
        r_peaks: List[Dict]
    ) -> str:
        """Build the analysis prompt for Gemini"""
        
        # Calculate HRV metrics
        hrv = self._calculate_hrv(r_peaks)
        
        # Extract data safely
        questionnaire = session.get("questionnaire", {})
        medical = profile.medical_history.__dict__ if profile and profile.medical_history else {}
        medications = profile.medications if profile else []
        med_names = ", ".join([m.medication_name for m in medications]) if medications else "None reported"
        
        prompt = f"""You are a medical AI assistant specialized in ECG analysis.
Analyze the following ECG data and provide insights at TWO levels: professional and layman.

## Patient Profile
- Age: {medical.get('age_at_record', 'Unknown')}
- Gender: {medical.get('gender', 'Unknown')}
- Existing Conditions: {medical.get('existing_conditions', 'None reported')}
- Current Medications: {med_names}

## Session Context
- Time of Day: {questionnaire.get('time_of_day', 'Unknown')}
- Caffeine Consumed (last 2 hrs): {questionnaire.get('caffeine_consumed', 'Unknown')}
- Nicotine Consumed: {questionnaire.get('nicotine_consumed', 'Unknown')}
- Activity Level: {questionnaire.get('activity_level', 'Unknown')}
- Stress Level: {questionnaire.get('stress_score', 'Unknown')}/5
- Additional Symptoms: {questionnaire.get('additional_symptoms', 'None')}

## ECG Session Metrics
- Duration: {session.get('duration_seconds', 0) or 0} seconds
- Average Heart Rate: {(session.get('average_heart_rate') or 0):.1f} BPM
- Maximum Heart Rate: {(session.get('max_heart_rate') or 0):.1f} BPM
- Minimum Heart Rate: {(session.get('min_heart_rate') or 0):.1f} BPM
- R-Peak Count: {session.get('r_peak_count', 0) or 0}
- HRV (SDNN): {(hrv.get('sdnn') or 0):.2f} ms
- HRV (RMSSD): {(hrv.get('rmssd') or 0):.2f} ms

Please provide your analysis in this exact JSON format:
{{
  "prediction": "Brief headline describing the main finding (e.g., 'Elevated Heart Rate with Moderate HRV')",
  "detailed_analysis": {{
    "rhythm_assessment": "Describe the heart rhythm pattern observed. Is it regular or irregular? What does the R-peak pattern suggest?",
    "rate_analysis": "Analyze the heart rate values. Is the average/max/min within normal range for the patient's profile? What might explain any deviations?",
    "hrv_interpretation": "Interpret the HRV values (SDNN, RMSSD). What do they indicate about the autonomic nervous system and stress levels?",
    "clinical_significance": "What is the overall clinical significance of these findings? Are there any patterns that warrant attention?"
  }},
  "clinical_analysis": "Comprehensive medical professional-level analysis summarizing all findings. Use proper medical terminology. Include rhythm, rate, HRV interpretation, and clinical implications. 6-8 sentences.",
  "simple_explanation": "Explain the findings in plain, friendly language that anyone can understand. Use analogies and relate to daily life. Be reassuring where appropriate. Focus on what matters most for the patient. 5-7 sentences.",
  "risk_level": "low|moderate|high|critical",
  "recommendations": [
    "Specific actionable recommendation 1",
    "Specific actionable recommendation 2", 
    "Specific actionable recommendation 3",
    "Lifestyle or follow-up recommendation 4"
  ],
  "summary": "One clear, concise sentence summarizing the most important takeaway from this analysis.",
  "confidence": 0.85
}}

Guidelines:
- "detailed_analysis" provides structured breakdown of each aspect
- "clinical_analysis" is for healthcare providers - be precise and use medical terminology
- "simple_explanation" is for regular users - avoid jargon, use everyday language
- "summary" must be exactly ONE sentence - the key takeaway a patient should remember
- Keep recommendations practical, specific, and actionable
- Be thorough but not unnecessarily alarming
- Consider the patient's profile (age, conditions, medications) in your analysis

IMPORTANT DISCLAIMER: This analysis is for informational purposes only and does not constitute medical advice. Always consult a qualified healthcare professional for medical concerns."""

        return prompt
    
    def _calculate_hrv(self, r_peaks: List[Dict]) -> Dict[str, float]:
        """Calculate Heart Rate Variability metrics from R-peaks"""
        if len(r_peaks) < 2:
            return {"sdnn": 0.0, "rmssd": 0.0}
        
        # Extract RR intervals
        rr_intervals = [
            p.get("rr_interval", 0) 
            for p in r_peaks 
            if p.get("rr_interval") and p.get("rr_interval") > 0
        ]
        
        if len(rr_intervals) < 2:
            return {"sdnn": 0.0, "rmssd": 0.0}
        
        try:
            # SDNN: Standard deviation of NN intervals
            sdnn = statistics.stdev(rr_intervals)
            
            # RMSSD: Root mean square of successive differences
            successive_diffs = [
                abs(rr_intervals[i+1] - rr_intervals[i]) 
                for i in range(len(rr_intervals) - 1)
            ]
            if successive_diffs:
                rmssd = (sum(d**2 for d in successive_diffs) / len(successive_diffs)) ** 0.5
            else:
                rmssd = 0.0
            
            return {"sdnn": sdnn, "rmssd": rmssd}
            
        except Exception:
            return {"sdnn": 0.0, "rmssd": 0.0}
    
    def _parse_response(self, text: str) -> Dict:
        """Parse Gemini response into structured data"""
        try:
            # Strip markdown code fences if present
            clean_text = text.strip()
            if clean_text.startswith("```"):
                # Remove opening fence (```json or ```)
                first_newline = clean_text.find('\n')
                if first_newline > 0:
                    clean_text = clean_text[first_newline + 1:]
                # Remove closing fence
                if clean_text.endswith("```"):
                    clean_text = clean_text[:-3].strip()
            
            # Find JSON in response
            start = clean_text.find('{')
            end = clean_text.rfind('}') + 1
            
            if start >= 0 and end > start:
                json_str = clean_text[start:end]
                data = json.loads(json_str)
                
                # Extract detailed analysis if present
                detailed = data.get("detailed_analysis", {})
                detailed_text = ""
                if isinstance(detailed, dict) and detailed:
                    detailed_text = f"""**Rhythm Assessment:** {detailed.get('rhythm_assessment', 'N/A')}

**Rate Analysis:** {detailed.get('rate_analysis', 'N/A')}

**HRV Interpretation:** {detailed.get('hrv_interpretation', 'N/A')}

**Clinical Significance:** {detailed.get('clinical_significance', 'N/A')}"""
                elif isinstance(detailed, str):
                    detailed_text = detailed
                
                return {
                    "prediction": data.get("prediction", "ECG Analysis Complete"),
                    "confidence_score": float(data.get("confidence", 0.75)),
                    "risk_level": data.get("risk_level", "low"),
                    "recommendations": data.get("recommendations", []),
                    "clinical_analysis": data.get("clinical_analysis", ""),
                    "diagnosis_summary": data.get("simple_explanation", ""),
                    "detailed_analysis": detailed_text,
                    "summary": data.get("summary", "")
                }
        except (json.JSONDecodeError, ValueError) as e:
            print(f"Error parsing Gemini response: {e}")
            print(f"Raw response: {text[:500]}")
        
        # Fallback: return raw text
        return {
            "prediction": text[:200] if len(text) > 200 else text,
            "confidence_score": 0.5,
            "risk_level": "low",
            "recommendations": ["Please consult a healthcare professional for interpretation"],
            "clinical_analysis": "",
            "diagnosis_summary": "",
            "detailed_analysis": "",
            "summary": ""
        }
    
    async def chat_with_context(
        self,
        user_message: str,
        context: str,
        user_profile,
        intent: str
    ) -> str:
        """
        Generate a conversational response for the chat assistant.
        
        Args:
            user_message: The user's question
            context: Session data context
            user_profile: User profile for personalization
            intent: Detected intent type
        """
        # Build profile context
        profile_context = ""
        if user_profile:
            medical = user_profile.medical_history.__dict__ if user_profile.medical_history else {}
            medications = user_profile.medications or []
            med_names = ", ".join([m.medication_name for m in medications]) if medications else "None"
            
            profile_context = f"""
## Your Profile
- Age: {medical.get('age_at_record', 'Not specified')}
- Gender: {medical.get('gender', 'Not specified')}
- Known Conditions: {medical.get('existing_conditions', 'None reported')}
- Current Medications: {med_names}
"""
        
        # Build the chat prompt
        prompt = f"""You are a friendly, knowledgeable cardiac health assistant for the PULSO ECG monitoring app.

Your role is to:
- Answer questions about ECG sessions and heart health
- Explain medical concepts in simple, understandable terms
- Provide helpful wellness recommendations
- Compare sessions when asked
- Be supportive and encouraging

{profile_context}

{context if context else ""}

## User's Question
{user_message}

## Response Guidelines
- Be conversational and friendly, like a helpful health companion
- Use simple language that anyone can understand
- If discussing specific data, reference the numbers clearly
- For comparisons, highlight key differences and what they might mean
- Always remind that this is not medical advice for serious concerns
- Keep responses concise but informative (2-4 paragraphs max)
- Use emojis sparingly for friendliness 💚

Respond naturally to the user's question:"""

        try:
            response = await self._call_gemini_api(prompt)
            # Clean up the response - remove any JSON formatting if present
            if response.startswith('{'):
                # Try to extract text if it's accidentally JSON
                return "I'm here to help! Could you please rephrase your question?"
            return response.strip()
        except Exception as e:
            print(f"Chat error: {e}")
            return "I'm having trouble connecting right now. Please try again in a moment! 🔄"

