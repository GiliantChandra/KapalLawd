"""
FastAPI app untuk development/testing (tanpa Modal)
Jalankan: python -m uvicorn dev_app:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Import OTP routes
from otp_routes import setup_otp_routes

# Create FastAPI app
app = FastAPI(
    title="StyleSense AI - Development API",
    description="Development server for testing OTP and hairstyle features",
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Setup OTP routes
setup_otp_routes(app)

# Health check
@app.get("/")
async def root():
    return {
        "status": "healthy",
        "service": "StyleSense AI - Development API",
        "features": ["whatsapp-otp", "sms-otp"]
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "StyleSense AI API",
        "features": ["hairstyle-generation", "whatsapp-otp"]
    }

@app.get("/docs")
async def get_docs():
    return {
        "message": "API Documentation available at /docs",
        "swagger_ui": "/docs",
        "redoc": "/redoc"
    }

# Note: Hairstyle endpoint removed for development testing
# Focus on OTP endpoints for now
# Install python-multipart if you need file upload features

if __name__ == "__main__":
    import uvicorn
    
    print("🚀 Starting StyleSense AI Development Server...")
    print("📡 API available at http://localhost:8000")
    print("📚 Docs at http://localhost:8000/docs")
    print("🔐 WhatsApp OTP endpoints enabled")
    print("")
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
