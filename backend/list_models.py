"""
Script to list available Gemini models
"""
import os
import httpx
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("ERROR: GEMINI_API_KEY not found in .env")
    exit(1)

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

print("Fetching available Gemini models...")
print("=" * 60)

response = httpx.get(url, timeout=30.0)

if response.status_code == 200:
    data = response.json()
    models = data.get("models", [])
    
    print(f"Found {len(models)} models:\n")
    
    for model in models:
        name = model.get("name", "Unknown")
        display_name = model.get("displayName", "")
        methods = model.get("supportedGenerationMethods", [])
        
        # Only show models that support generateContent
        if "generateContent" in methods:
            print(f"✅ {name}")
            print(f"   Display: {display_name}")
            print(f"   Methods: {', '.join(methods)}")
            print()
else:
    print(f"Error: {response.status_code}")
    print(response.text)
