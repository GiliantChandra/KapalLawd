import modal
import os

app = modal.App("kapallawd-trainer")

# Racikan RAM dan Sistem Cloud Independen yang Bebas dari jerat Python 3.14 Lokal Anda!
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("libgl1", "libglib2.0-0")
    .pip_install(
        "tensorflow<2.16",
        "protobuf<4",
        "keras",
        "opencv-python-headless", 
        "numpy", 
        "mediapipe==0.10.5", 
        "scikit-learn", 
        "tqdm"
    )
    # [AJAIB] Folder 'dataset' di laptop akan disedot dan dicor permanen ke Hardisk AWS/Modal!
    .add_local_dir("dataset", remote_path="/root/dataset")
    # File Script otak latihannya pun dibawa terbang ke Image Docker!
    .add_local_file("train_face_shape_classifier.py", remote_path="/root/train_face_shape_classifier.py")
)

# Memeras tenaga GPU T4 dari Amerika murni untuk hitung mundur Epoch!
@app.function(
    image=image,
    gpu="T4",
    timeout=3600 # Kunci sabuk pengaman toleransi Limit 1 Jam
)
def train_model():
    print("🔥 PROSES TRAINING DIMULAI DI DALAM GPU AWAN...")
    import sys
    sys.path.append("/root")
    
    import train_face_shape_classifier
    trainer = train_face_shape_classifier.FaceShapeTrainer()
    
    print("⚙️ Mengekstrak Poligon Wajah dan Membangkitkan Matrix...")
    # Pelaksanaan: Latihan 50 Putaran (Sangat cukup berkat Transfer Learning MobileNet)
    model, history = trainer.train("/root/dataset", epochs=50, batch_size=32)
    
    print("✅ Training Penuh Berhasil Diselesaikan Tanpa Hambatan Spesifikasi CPU Lokal!")
    print("📦 Mengemas Artefak Otak AI ('face_shape_hybrid_classifier.h5') untuk dikirim pulang ke bumi...")
    
    # Sang awan menangkap hasil keringat berlatih (Binari H5 File)
    with open("face_shape_hybrid_classifier.h5", "rb") as f:
        file_bytes = f.read()
    
    return file_bytes

@app.local_entrypoint()
def main():
    print("================================================================")
    print("🚀 Mengangkut ribuan foto ke Langit Modal untuk dilatih GPU Awan... ")
    print("⚠️ Tampilan layar mungkin terlihat 'diam', tapi GPU sedang BEKERJA KERAS!")
    print("⚠️ Harap JANGAN TUTUP Terminal VSCode Anda sampai proses tamat!")
    print("================================================================")
    
    # Tunggu Awan menyelesaikan proses berat dan panggil hasilnya
    file_bytes = train_model.remote()
    
    print("🛬 Menjemput file AI yang sudah Cerdas dari Awan membelah ke Laptop Lokal Anda...")
    
    # Suntikkan langsung file mistik ke alam harddisk lokal!
    with open("face_shape_hybrid_classifier.h5", "wb") as f:
        f.write(file_bytes)
        
    print("🎉 SELESAI! Otak Penebak Wajah 'face_shape_hybrid_classifier.h5' telah mendarat dengan selamat di folder backend Anda.")
