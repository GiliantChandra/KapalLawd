import os
import modal
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import ai_engine

# 1. Definisikan Environment & Bawaan (Pip Install di Cloud Modal)
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("libgl1", "libglib2.0-0") # Dibutuhkan mutlak untuk OpenCV Python
    .pip_install(
        "fastapi[standard]",
        "python-multipart",
        "diffusers",
        "torch",
        "transformers",
        "accelerate",
        "opencv-python-headless",
        "numpy",
        "Pillow",
    )
)

app = modal.App("kapallawd-ai", image=image)
fastapi_app = FastAPI(title="Modal Serverless GPU API")

# Membuka gerbang bagi aplikasi Flutter
fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@fastapi_app.post("/generate-hairstyle")
async def generate_hairstyle(
    user_id: str = Form(...),
    style_name: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        # Gunakan sistem file ephemeral /tmp bawaan VPS Linux
        temp_file_path = f"/tmp/{image.filename}"
        
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        print(f"[{user_id}] Memulai kalkulasi Stable Diffusion untuk gaya {style_name}...")
        
        # Eksekusi AI yang sudah dirombak me-return Base64
        generator = ai_engine.get_generator()
        result_data = generator.generate(user_id, style_name, temp_file_path)
        
        if "error" in result_data:
            raise HTTPException(status_code=500, detail=result_data["error"])
            
        # Hapus gambar mentah demi privasi mutlak user
        os.remove(temp_file_path)
        
        # Mengembalikan string Base64 
        return result_data
        
    except Exception as e:
        print(f"Error fatal eksekusi Serverless: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Titik eksekusi khusus layanan Modal
@app.function(
    gpu="T4",
    timeout=600,
    min_containers=1, # Mencegah latency cold-start bagi user pertama
    memory=8192
)
@modal.asgi_app()
def fastapi_endpoint():
    return fastapi_app
