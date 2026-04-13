import os
import modal
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil

# Fungsi untuk Mem-bakar (Baking/Caching) File Raksasa Stable Diffusion ke Harddisk Server Cloud
# Memotong Waktu Loading (Cold-Start) dari 4 Menit menjadi 15 Detik!
def download_ai_models():
    import torch
    from diffusers import StableDiffusionInpaintPipeline
    print("Mendownload Otak Stable Diffusion secara permanen ke Image Cache...")
    StableDiffusionInpaintPipeline.from_pretrained(
        "runwayml/stable-diffusion-inpainting",
        torch_dtype=torch.float16,
        safety_checker=None,
        requires_safety_checker=False
    )
    print("Download Selesai. Model AI kini terkunci di Harddisk Cloud Modal!")

# Merakit Image Komputer Khusus untuk KapalLawd
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("libgl1", "libglib2.0-0", "wget")
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
        "mediapipe==0.10.5",
        "tensorflow<2.16",
        "protobuf<4",
        "keras",
        "scikit-learn",
        "pandas",
        "twilio",        
        "python-dotenv", 
        "requests",      
    )
    .run_function(download_ai_models) # Mengeksekusi Download saat Tahap Deployment
    .add_local_file('face_shape_hybrid_classifier.h5', remote_path='/root/face_shape_hybrid_classifier.h5')
)

app = modal.App("kapallawd-ai", image=image)
fastapi_app = FastAPI(title="Modal Serverless GPU API")

fastapi_app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Integrasi Rute Khusus OTP (WhatsApp) bila pengguna masih memakainya
try:
    from otp_routes import setup_otp_routes
    setup_otp_routes(fastapi_app)
except Exception as e:
    print(f"Peringatan: Gagal memuat OTP Routes: {e}")


@fastapi_app.post("/generate-hairstyle")
async def generate_hairstyle(
    user_id: str = Form(...),
    style_name: str = Form(...),
    image: UploadFile = File(...)
):
    try:
        temp_file_path = f"/tmp/{image.filename}"
        
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        print(f"[{user_id}] Memulai Eksekusi Tensor Raksasa untuk gaya {style_name}...")
        
        # Mengimpor modul AI Engine secara bertahap saat API di-hit 
        import ai_engine
        generator = ai_engine.get_generator()
        
        # Mengeksekusi lukisan Neural (Generasi Wajah)
        result_data = generator.generate_hairstyle(user_id, style_name, temp_file_path)
        
        if "error" in result_data:
            raise HTTPException(status_code=500, detail=result_data["error"])
            
        # Pembersihan file sampah
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
            
        return result_data
        
    except Exception as e:
        print(f"Bencana Serverless Fatal: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# ================= RAHASIA KECEPATAN (LIMIT GPU & RAM TINGKAT DEWA) ================= #
# Memory 32 GB dan Timeout Maksimal untuk Menahan Benturan PyTorch + TensorFlow
@app.function(
    gpu="T4",
    timeout=600,
    min_containers=1,          # Tetap panaskan 1 Komputer agar tidak tertidur
    memory=32768               # DITINGKATKAN DARI 8GB KE 32GB AGAR TIDAK MATI KEKURANGAN NAFAS!
)
@modal.asgi_app()
def fastapi_endpoint():
    return fastapi_app