"""
PULSO ECG Analysis API
FastAPI application with security middleware
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from contextlib import asynccontextmanager

from .config import get_settings
from .routers import ecg, analysis, user, chat


# Rate limiter instance
limiter = Limiter(key_func=get_remote_address)


# Create FastAPI application
app = FastAPI(
    title="PULSO ECG Analysis API",
    description="""
    Backend API for PULSO ECG Analysis Application.
    
    ## Features
    - ECG session management with questionnaires
    - ECG chart snapshot uploads
    - Gemini AI-powered ECG analysis
    - User profile and medication tracking
    
    ## Security
    - JWT authentication via Supabase
    - Rate limiting on analysis endpoints
    - Input sanitization
    """,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add rate limiter to app state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Configuration
# In production, replace "*" with your actual frontend domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions"""
    settings = get_settings()
    
    if settings.environment == "development":
        # Show detailed error in development
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "detail": str(exc),
                "type": type(exc).__name__
            }
        )
    else:
        # Generic error in production
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"detail": "Internal server error"}
        )


# Include routers
app.include_router(ecg.router, prefix="/api/v1/ecg", tags=["ECG"])
app.include_router(analysis.router, prefix="/api/v1/analysis", tags=["Analysis"])
app.include_router(user.router, prefix="/api/v1/user", tags=["User"])
app.include_router(chat.router, prefix="/api/v1", tags=["Chat"])


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "service": "pulso-api",
        "version": "1.0.0"
    }


@app.get("/", tags=["Health"])
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to PULSO ECG Analysis API",
        "docs": "/docs",
        "health": "/health"
    }
