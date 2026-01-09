# PULSO 💓

A minimally invasive heart monitoring system that leverages AI-powered ECG analysis for accessible cardiac health monitoring.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

## 🌟 Features

- **🤖 AI-Powered ECG Analysis** - Gemini AI integration for intelligent ECG interpretation
- **📊 ECG Session Management** - Record, store, and track ECG sessions over time
- **💊 Medication Tracking** - Keep track of medications and health routines
- **🔐 Secure Authentication** - JWT-based authentication via Supabase
- **📱 Cross-Platform** - Available on Android, iOS, Web, Windows, macOS, and Linux

## 🏗️ Project Structure

```
PULSO/
├── lib/                    # Flutter application source code
├── backend/                # FastAPI backend server
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── web/                    # Web-specific files
├── windows/                # Windows-specific files
├── macos/                  # macOS-specific files
├── linux/                  # Linux-specific files
├── packages/               # Custom packages
├── supabase_migrations/    # Database migrations
└── test/                   # Test files
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Python 3.10+](https://www.python.org/downloads/)
- [Supabase Account](https://supabase.com/)
- [Google Gemini API Key](https://ai.google.dev/)

### Frontend Setup (Flutter)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nik1740/PULSO.git
   cd PULSO
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Backend Setup (FastAPI)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment:**
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment:**
   - Copy `.env.example` to `.env`
   - Add your Supabase and Gemini API keys

5. **Run the server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access API documentation:**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## 📡 API Endpoints

### ECG Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ecg/questionnaire` | Save session questionnaire |
| POST | `/api/v1/ecg/snapshot/{reading_id}` | Upload ECG image |
| GET | `/api/v1/ecg/session/{reading_id}` | Get session details |
| GET | `/api/v1/ecg/sessions` | List user sessions |

### Analysis Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/analysis/request/{reading_id}` | Request AI analysis |
| GET | `/api/v1/analysis/{reading_id}` | Get analysis results |
| GET | `/api/v1/analysis/history/list` | Get analysis history |

### User Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/user/profile` | Get user profile |
| GET | `/api/v1/user/medications` | List medications |
| POST | `/api/v1/user/medications` | Add medication |

## 🔒 Security Features

- **JWT Authentication** - All endpoints require authentication (except health check)
- **Rate Limiting** - Analysis endpoint limited to 5 requests/hour
- **Input Sanitization** - Protection against XSS attacks

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter / Dart |
| Backend | FastAPI / Python |
| Database | Supabase (PostgreSQL) |
| AI/ML | Google Gemini |
| Authentication | Supabase Auth (JWT) |

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Gemini AI Documentation](https://ai.google.dev/docs)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source. See the repository for license details.

---

<p align="center">Made with ❤️ for better heart health</p>