import os
import re
import time
import shutil
import hashlib
from collections import defaultdict
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import nest_asyncio
import uvicorn

# ============================================================
# [KEAMANAN 1] FIREBASE ADMIN SDK — Verifikasi Token
# Upload file serviceAccountKey.json ke /content/ di Colab
# Download dari: Firebase Console → Project Settings → Service Accounts
# ============================================================
import firebase_admin
from firebase_admin import credentials, auth as firebase_auth

_firebase_initialized = False
try:
    # Cari serviceAccountKey.json di beberapa lokasi (urutan prioritas):
    # 1. Folder /content/ (upload manual ke Colab)
    # 2. Google Drive (simpan sekali, pakai selamanya!)
    _key_candidates = [
        '/content/serviceAccountKey.json',
        '/content/drive/MyDrive/KapalLawd/serviceAccountKey.json',
        '/content/drive/My Drive/KapalLawd/serviceAccountKey.json',
    ]
    service_account_path = next((p for p in _key_candidates if os.path.exists(p)), None)

    if service_account_path:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        print(f"✅ Firebase Admin SDK siap! (dari: {service_account_path})")
    else:
        print("⚠️ serviceAccountKey.json tidak ditemukan di:")
        for p in _key_candidates:
            print(f"   - {p}")
        print("   → Simpan file ke salah satu lokasi di atas.")
        print("   → Verifikasi token DINONAKTIFKAN sementara.")
except Exception as e:
    print(f"⚠️ Firebase Admin gagal inisialisasi: {e}")

def verify_firebase_token(authorization: str) -> str:
    """Verifikasi Firebase ID Token dan kembalikan UID yang valid."""
    if not _firebase_initialized:
        # Fallback: jika Admin SDK tidak tersedia, tolak semua request demi keamanan
        raise HTTPException(status_code=503, detail="Server auth belum siap. Upload serviceAccountKey.json.")
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Authorization header tidak valid. Format: Bearer <token>")
    id_token = authorization.split("Bearer ")[1].strip()
    try:
        decoded = firebase_auth.verify_id_token(id_token)
        return decoded['uid']  # UID yang sudah diverifikasi secara kriptografis
    except firebase_admin.exceptions.FirebaseError as e:
        raise HTTPException(status_code=401, detail=f"Token tidak valid atau kadaluarsa: {str(e)}")

# ============================================================
# [KEAMANAN 2] RATE LIMITING — Maks 5 request/menit per user
# ============================================================
rate_limit_store = defaultdict(list)
MAX_REQUESTS_PER_MINUTE = 5

def check_rate_limit(user_id: str):
    now = time.time()
    rate_limit_store[user_id] = [t for t in rate_limit_store[user_id] if now - t < 60]
    if len(rate_limit_store[user_id]) >= MAX_REQUESTS_PER_MINUTE:
        raise HTTPException(status_code=429, detail=f"Terlalu banyak request. Maksimal {MAX_REQUESTS_PER_MINUTE}x per menit.")
    rate_limit_store[user_id].append(now)

# ============================================================
# [KEAMANAN 3] VALIDASI INPUT + MAGIC BYTES
# ============================================================
ALLOWED_MIME_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB
ALLOWED_STYLE_PATTERN = re.compile(r'^[a-zA-Z0-9 _\-]{1,50}$')

# Magic bytes: tanda tangan biner unik setiap format gambar (tidak bisa dipalsukan)
IMAGE_MAGIC_BYTES = [
    (b'\xff\xd8\xff', 'JPEG'),           # JPEG/JPG
    (b'\x89PNG\r\n\x1a\n', 'PNG'),       # PNG
    (b'RIFF', 'WEBP'),                   # WEBP (4 bytes pertama)
]

def verify_magic_bytes(content: bytes):
    """Pastikan file benar-benar gambar dengan memeriksa byte awal file."""
    for magic, fmt in IMAGE_MAGIC_BYTES:
        if content[:len(magic)] == magic:
            return  # Valid
    raise HTTPException(status_code=400, detail="File bukan gambar valid. Konten tidak sesuai format gambar.")

def validate_style_name(style_name: str):
    if not ALLOWED_STYLE_PATTERN.match(style_name):
        raise HTTPException(status_code=400, detail="Nama style mengandung karakter tidak valid.")

app = FastAPI(title="StyleSense AI — Secured GPU API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Di produksi: ganti dengan domain spesifik
    allow_methods=["POST"],
    allow_headers=["*"],
)

# ============================================================
# [KEAMANAN 4] SECURITY HEADERS MIDDLEWARE
# ============================================================
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "no-referrer"
    return response

print("🚀 Sedang Menyiapkan Mesin AI Engine Langsung dari Google Colab...")
generator = None  # Pastikan variabel selalu ada meskipun loading gagal
startup_error = None

try:
    import ai_engine
    generator = ai_engine.get_generator()
    print("✅ AI Engine Siaga 100%!")
except Exception as e:
    startup_error = str(e)
    print(f"❌ Gagal memuat AI Engine: {e}")
    import traceback
    traceback.print_exc()

@app.post("/generate-hairstyle")
async def generate_hairstyle(
    style_name: str = Form(...),
    image: UploadFile = File(...),
    authorization: str = Header(None)  # Firebase ID Token: "Bearer <token>"
):
    # ── [KEAMANAN 1] Verifikasi Firebase ID Token ───────────────
    # Token di-generate oleh Firebase Auth di HP, diverifikasi kriptografis di sini
    verified_uid = verify_firebase_token(authorization)

    # ── [KEAMANAN 2] Rate Limiting per user yang sudah terverifikasi ──
    check_rate_limit(verified_uid)

    # ── [KEAMANAN 3] Sanitasi style_name ────────────────────────
    validate_style_name(style_name)

    # Cek apakah generator sudah siap
    if generator is None:
        raise HTTPException(status_code=503, detail="AI Engine belum siap. Cek log Colab.")

    try:
        # Baca konten file terlebih dahulu untuk validasi
        content = await image.read()

        # ── [KEAMANAN 4] Validasi ukuran file ───────────────────
        if len(content) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(status_code=413, detail=f"File terlalu besar. Maksimal {MAX_FILE_SIZE_BYTES // (1024*1024)} MB.")

        # ── [KEAMANAN 5] Magic Bytes — verifikasi konten file ───
        verify_magic_bytes(content)

        # ── [KEAMANAN 6] Path Traversal Prevention ──────────────
        # Nama file di-hash agar tidak bisa dimanipulasi penyerang
        safe_filename = hashlib.md5(f"{verified_uid}{time.time()}".encode()).hexdigest()
        temp_file_path = f"/tmp/upload_{safe_filename}.jpg"

        with open(temp_file_path, "wb") as buffer:
            buffer.write(content)

        print(f"✅ [AMAN] uid={verified_uid[:8]}... | style={style_name} | size={len(content)//1024}KB")

        # Eksekusi AI dengan UID yang sudah terverifikasi (bukan dari input user)
        result_data = generator.generate_hairstyle(verified_uid, style_name, temp_file_path)

        if "error" in result_data:
            raise HTTPException(status_code=500, detail=result_data["error"])

        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)

        return result_data

    except HTTPException:
        raise
    except Exception as e:
        # [KEAMANAN 6] Jangan ekspos detail error internal ke client
        print(f"❌ Server Error: {e}")
        import traceback
        traceback.print_exc()
        # Pesan generik ke client, detail hanya di log server
        raise HTTPException(status_code=500, detail="Terjadi kesalahan pada server. Coba beberapa saat lagi.")

if __name__ == "__main__":
    # Nest-Asyncio digunakan agar uvicorn bisa berjalan mulus berdampingan di lingkungan Colab
    nest_asyncio.apply()
    uvicorn.run(app, host="0.0.0.0", port=8000)
