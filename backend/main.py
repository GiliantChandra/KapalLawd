import os
import shutil
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import FileResponse
import uvicorn
import firebase_admin
from firebase_admin import credentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
import shutil
import uuid

from ai_engine import generator

# Initialize FastAPI
app = FastAPI(title="StyleSense AI Hair Recommendation API")

# Initialize Firebase Admin SDK (will be configured later with service account)
# cred = credentials.Certificate("path/to/serviceAccountKey.json")
# firebase_admin.initialize_app(cred, {'storageBucket': 'kapallawd-70c45.appspot.com'})

# Buat direktori temp dan history cloud lokal
os.makedirs("temp_uploads", exist_ok=True)
os.makedirs("history", exist_ok=True)

# Jadikan Python Server bertransformasi menjadi Cloud Storage Hosting
app.mount("/history", StaticFiles(directory="history"), name="history")

@app.get("/")
def read_root():
    return {"status": "ok", "message": "ML Server is running"}

@app.post("/generate-hairstyle")
async def generate_hairstyle(
    user_id: str = Form(...),
    style_name: str = Form(...),
    image: UploadFile = File(...)
):
    """
    Endpoint utama untuk memproses AI Haircut.
    Menerima foto asli wajah user dan gaya yang dipilih, memproses dengan PyTorch,
    dan mengembalikan URL foto hasil.
    """
    print(f"Menerima request untuk User: {user_id}, Style Target: {style_name}")
    
    try:
        # 1. Simpan gambar yang diupload ke direktori temporary
        temp_file_path = os.path.join("temp_uploads", image.filename)
        
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        # 2. PROSES AI GAMBAR! (Akan memanggil Diffusers Inpainting dan MediaPipe)
        result_data = generator.generate(user_id, style_name, temp_file_path)
        
        if "error" in result_data:
            raise HTTPException(status_code=500, detail=result_data["error"])
            
        result_path = result_data["result_path"]
        face_shape = result_data["face_shape"]
        style_applied = result_data["style_applied"]
        
        if not os.path.exists(result_path):
            raise Exception("File hasil gagal diproses")
            
        # Simpan ke folder hosting 'history' agar HP bisa memanggilnya seperti link URL biasa
        history_filename = f"{uuid.uuid4().hex}.jpg"
        history_path = os.path.join("history", history_filename)
        shutil.copy(result_path, history_path)

        # 3. Kembalikan file gambar beserta metadata khusus di HTTP Headers
        headers = {
            "X-Face-Shape": face_shape,
            "X-Style-Applied": style_applied,
            "X-Image-Filename": history_filename
        }
        
        return FileResponse(
            result_path, 
            media_type="image/jpeg", 
            filename="result.jpg",
            headers=headers
        )
        
    except Exception as e:
        print(f"Error di backend: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
