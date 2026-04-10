"""
Contoh integrasi WhatsApp OTP ke modal_app.py

Ganti modal_app.py Anda dengan code ini untuk menambahkan OTP functionality.
"""

import os
import modal
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import shutil
from typing import UploadFile
import ai_engine
from otp_routes import setup_otp_routes  # NEW: Import OTP routes

# Load environment variables
load_dotenv()

# 1. Definisikan Environment & Bawaan (Pip Install di Cloud Modal)
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("libgl1", "libglib2.0-0", "wget", "bzip2")
    .run_commands(
        "wget -O /tmp/shape_predictor_68_face_landmarks.dat.bz2 http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2",
        "bunzip2 /tmp/shape_predictor_68_face_landmarks.dat.bz2",
        "mv /tmp/shape_predictor_68_face_landmarks.dat /opt/"
    )
    .pip_install(
        "fastapi[standard]",
        "python-multipart",
        "twilio",  # NEW: Add Twilio for WhatsApp
        "python-dotenv",  # NEW: Add dotenv for env variables
        "diffusers",
        "torch",
        "transformers",
        "accelerate",
        "opencv-python-headless",
        "numpy",
        "Pillow",
        "mediapipe",
        "dlib",
        "tensorflow",
        "keras",
        "scikit-learn",
        "pandas",
        "matplotlib",
        "seaborn",
    )
)

app = modal.App("kapallawd-ai", image=image)
fastapi_app = FastAPI(title="Modal Serverless GPU API")

# CORS Configuration - Allow Flutter app to access API
fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to your domain in production
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== NEW: Setup OTP Routes =====
setup_otp_routes(fastapi_app)
# ================================

@fastapi_app.post("/generate-hairstyle")
async def generate_hairstyle(
    user_id: str = None,
    style_name: str = None,
    image: UploadFile = None
):
    """Generate hairstyle using AI"""
    try:
        temp_file_path = f"/tmp/{image.filename}"
        
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        print(f"[{user_id}] Memulai kalkulasi Stable Diffusion untuk gaya {style_name}...")
        
        generator = ai_engine.get_generator()
        result_data = generator.generate_hairstyle(user_id, style_name, temp_file_path)
        
        if "error" in result_data:
            return {"error": result_data["error"]}, 500
            
        os.remove(temp_file_path)
        
        return result_data
        
    except Exception as e:
        print(f"Error fatal eksekusi Serverless: {e}")
        return {"error": str(e)}, 500


@fastapi_app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "StyleSense AI API",
        "features": ["hairstyle-generation", "whatsapp-otp"]
    }


# Titik eksekusi khusus layanan Modal
@app.function(
    gpu="T4",
    timeout=600,
    min_containers=1,
    memory=8192
)
@modal.asgi_app()
def fastapi_endpoint():
    return fastapi_app


if __name__ == "__main__":
    import uvicorn
    
    # Development server - local testing
    print("🚀 Starting StyleSense AI Backend Server...")
    print("📡 API available at http://localhost:8000")
    print("📚 Docs at http://localhost:8000/docs")
    print("🔐 WhatsApp OTP endpoints enabled")
    
    uvicorn.run(
        fastapi_app,
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
