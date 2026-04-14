import os
import shutil
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import nest_asyncio
import uvicorn

app = FastAPI(title="Google Colab Serverless GPU API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Sedang Menyiapkan Mesin AI Engine Langsung dari Google Colab...")
try:
    import ai_engine
    generator = ai_engine.get_generator()
    print("✅ AI Engine Siaga 100%!")
except Exception as e:
    print(f"❌ Gagal memuat AI Engine: {e}")

@app.post("/generate-hairstyle")
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
        
        # Mengeksekusi lukisan Neural (Generasi Wajah)
        result_data = generator.generate_hairstyle(user_id, style_name, temp_file_path)
        
        if "error" in result_data:
            raise HTTPException(status_code=500, detail=result_data["error"])
            
        # Pembersihan file sampah
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
            
        return result_data
        
    except Exception as e:
        print(f"Bencana Server Fatal: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Nest-Asyncio digunakan agar uvicorn bisa berjalan mulus berdampingan di lingkungan Colab
    nest_asyncio.apply()
    uvicorn.run(app, host="0.0.0.0", port=8000)
