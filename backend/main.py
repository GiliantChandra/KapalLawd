import os
import shutil
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse, FileResponse
import uvicorn
import firebase_admin
from firebase_admin import credentials, storage
import shutil

from ai_engine import generator

# Initialize FastAPI
app = FastAPI(title="StyleSense AI Hair Recommendation API")

# Initialize Firebase Admin SDK (will be configured later with service account)
# cred = credentials.Certificate("path/to/serviceAccountKey.json")
# firebase_admin.initialize_app(cred, {'storageBucket': 'kapallawd-70c45.appspot.com'})

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
    try:
        # 1. Simpan gambar sementara dari request HTTP Flutter
        temp_input_path = f"temp_input_{user_id}.jpg"
        with open(temp_input_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
            
        print(f"Menerima request untuk user {user_id} dengan style: {style_name}")
        
        # 2. Panggil Modul AI (Image-to-Image Pipeline)
        # Target style image (saat ini AI akan mengenerate berbasis teks dari style_name, atau bisa di-route ke file)
        target_style_path = "" 
        
        result_path = generator.generate(temp_input_path, style_name, target_style_path)
        
        # 3. Kembalikan file hasil ke aplikasi Flutter (Lalu akan dihapus otomatis dengan background task / manual cleanup nanti)
        if not os.path.exists(result_path):
            raise Exception("File hasil gagal diproses")
            
        return FileResponse(result_path, media_type="image/jpeg", filename="result.jpg")

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
