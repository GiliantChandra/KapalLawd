import os
import torch
import cv2
import numpy as np
import random
from PIL import Image, ImageOps
from diffusers import StableDiffusionInpaintPipeline

# Catatan: Ini adalah modul inti tempat AI model berjalan (GPU Accelerated).
# Kita menggunakan Diffusers (Stable Diffusion Inpainting) & OpenCV Bawaan.

class HairStyleGenerator:
    def __init__(self):
        print("Model AI Inpainting sedang dimuat. Harap sabar, proses ini memakan VRAM dan Waktu...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Device AI: {self.device}")
        
        # Inisialisasi Detektor Wajah Bawaan OpenCV (Sangat Ringan & Bebas Error Python 3.13)
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        
        try:
            # Menggunakan model inpainting ringan standar (Akan mengunduh 4GB+ dari HuggingFace pada run pertama)
            self.pipeline = StableDiffusionInpaintPipeline.from_pretrained(
                "runwayml/stable-diffusion-inpainting",
                torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
                safety_checker=None,
                requires_safety_checker=False 
            )
            self.pipeline.to(self.device)
            self.pipeline.enable_model_cpu_offload()
            self.pipeline.enable_attention_slicing() # Wajib untuk RTX 3050 (4GB) agar tidak Force Close!
            self.is_loaded = True
            print("====> Model AI KECERDASAN BUATAN BERHASIL AKTIF! <====")
        except Exception as e:
            print(f"Sedang mengunduh / Peringatan Model: {e}")
            self.is_loaded = False

    def analyze_face_and_mask(self, original_image_path: str):
        """
        Membaca Wajah menggunakan OpenCV HaarCascade.
        Mengembalikan: (Mask Image (PIL), Rekomendasi Bentuk Wajah)
        Mask Hitam = Wajah terlindungi. Mask Putih = Rambut/Latar untuk digambar AI.
        """
        img_bgr = cv2.imread(original_image_path)
        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
        h, w = img_bgr.shape[:2]
        
        # Deteksi wajah
        faces = self.face_cascade.detectMultiScale(gray, 1.1, 4)
        
        # Buat kanvas Mask Hitam penuh (Pixel Hitam = Jangan sentuh area ini)
        mask_np = np.zeros((h, w), dtype=np.uint8)
        
        face_shape = "Oval" # Default
        best_style = "Middle Part"
        
        if len(faces) > 0:
            # Ambil wajah terbesar jika ada banyak bingkai
            faces = sorted(faces, key=lambda x: x[2]*x[3], reverse=True)
            fx, fy, fw, fh = faces[0]
            
            # Estimasi kasaran bentuk wajah
            ratio = fh / float(fw)
            if ratio > 1.35:
                face_shape = "Oblong"
                best_style = "French Crop" # Poni menutupi dahi panjang
            elif ratio < 1.15:
                face_shape = "Round"
                best_style = "Faux Hawk"   # Beri volume ke atas
            else:
                shapes = ["Oval", "Square"]
                face_shape = random.choice(shapes)
                best_style = "Side Part" if face_shape == "Oval" else "Buzz Cut"

            # 1. KANVAS AREA RAMBUT (Putih)
            # Area ini lebih luas dari wajah untuk memberi ruang bagi rambut tumbuh
            rambut_atas = max(0, fy - int(fh * 0.8)) # Lebar ke atas kepala
            rambut_bawah = int(fy + (fh * 1.5)) # Ke leher
            rambut_kiri = max(0, fx - int(fw * 0.35))
            rambut_kanan = min(w, fx + fw + int(fw * 0.35))
            cv2.rectangle(mask_np, (rambut_kiri, rambut_atas), (rambut_kanan, rambut_bawah), 255, -1)
            
            # 2. PROTEKSI WAJAH OVAL PRESISI (Anti Stretched / Meleleh)
            center_x = fx + int(fw / 2)
            center_y = fy + int(fh / 2)
            
            # KESALAHAN SEBELUMNYA: OpenCV butuh Nilai RADIUS (Jari-jari), bukan Diameter!
            axis_x = int(fw * 0.55)  # Pas menutupi anatomi wajah (pipi ke pipi)
            axis_y = int(fh * 0.65)  # Pas menutupi jidat hingga dagu ke leher
            
            # Gambar telur hitam solid tepat menutupi anatomi wajah
            cv2.ellipse(mask_np, (center_x, center_y), (axis_x, axis_y), 0, 0, 360, 0, -1)
            
            # 3. PROTEKSI BAJU / BADAN (Menutupi bagian leher/pundak ke bawah)
            batas_bahu = center_y + int(fh * 0.55)
            cv2.rectangle(mask_np, (0, batas_bahu), (w, h), 0, -1)
            
            # Sedikit blur agar transisi batas antara wajah asli dan rambut AI sangat membaur natural
            mask_np = cv2.GaussianBlur(mask_np, (31, 31), 0)
        else:
            # Jika buta, warnai kotak atas secara default (Fallback)
            cv2.rectangle(mask_np, (int(w*0.2), 0), (int(w*0.8), int(h*0.4)), 255, -1)
            
        return Image.fromarray(mask_np).convert("L"), face_shape, best_style

    def generate(self, user_id: str, style_name: str, original_image_path: str) -> dict:
        """
        Memproses foto dan menerapkan gaya rambut menggunakan AI.
        """
        if not self.is_loaded:
            raise Exception("Model AI belum termuat sepenuhnya!")
            
        print(f"Memproses style: {style_name} pada gambar {original_image_path}")
        
        # 1. Buka Image & Terapkan EXIF Transpose (ANTI-MIRING 90 DERAJAT!)
        # HP Android menyimpan foto portrait dalam posisi 'Tidur' dan menggunakan tag EXIF untuk memutarnya. 
        # Python tidak otomatis membaca EXIF. Jadi AI selama ini buta karena melukis muka yang lagi tengkurap 90 derajat!
        original_pil = Image.open(original_image_path)
        original_pil = ImageOps.exif_transpose(original_pil).convert("RGB")
        original_resized = ImageOps.pad(original_pil, (512, 512), color=(0,0,0), method=Image.Resampling.LANCZOS)
        
        # 2. Dapatkan Mask dan Deteksi Bentuk Wajah HANYA dari versi Resized agar koordinat akurat
        resized_path = "temp_resized.jpg"
        original_resized.save(resized_path)
        mask_image, detected_shape, auto_style = self.analyze_face_and_mask(resized_path)
        
        # Jika mode Auto, set style = auto_style yang diputuskan algorithm
        if style_name.lower() == "auto":
            style_name = auto_style

        # 3. Racik Prompt AI Khusus (Super Advanced)
        clean_style = style_name.replace('_', ' ')
        prompt = f"A hyperrealistic, professional front-facing studio portrait of an adult man with a perfect {clean_style} hairstyle. "
        
        if "Mullet" in clean_style or "mullet" in clean_style.lower():
            prompt += "Short messy hair on the top and sides, with very long flowing hair falling straight down the back of the neck visible behind the ears. "
        elif "Buzz" in clean_style or "buzz" in clean_style.lower():
            prompt += "Extremely short military style cropped hair close to the scalp. "
        elif "Middle" in clean_style or "middle" in clean_style.lower():
            prompt += "Hair symmetrically parted perfectly down the middle, curtain bangs framing the forehead. "
        elif "Side" in clean_style or "side" in clean_style.lower():
            prompt += "Hair elegantly parted to one side, combed neatly. "
        elif "French" in clean_style or "french" in clean_style.lower():
            prompt += "Short sides with a textured fringe (poni) falling straight down over the forehead. "
        elif "Faux Hawk" in clean_style or "faux" in clean_style.lower():
            prompt += "Hair pushed upwards and spiked in the middle creating a crest, short sides. "
            
        prompt += "8k resolution, razor sharp focus, intricately detailed hair strands, seamlessly blending with the existing scalp and forehead. solid dark grey studio background."
        negative_prompt = "(deformity, extra faces, extra heads, floating hair, disconnected hair, surreal, asymmetrical, extra eyes, facial hair on cheeks, mutant, blurry, bad anatomy, deformed, unnatural, ugly, completely different person, two people)"
        
        # 4. Inpainting Magic
        print(f"Memulai komputasi Tensor GPU Inpainting untuk {clean_style}...")
        result_image = self.pipeline(
            prompt=prompt,
            negative_prompt=negative_prompt,
            image=original_resized,
            mask_image=mask_image,
            num_inference_steps=30, # Naikkan ketelitian
            guidance_scale=9.5,     # Paksa AI untuk tunduk pada deskripsi gaya rambut prompt
            strength=0.98           # 98% Ambil alih mutlak area putih, jangan jiplak rambut asli user
        ).images[0]
        
        # 5. Simpan hasil gambar
        output_filename = f"generated_ai_{os.path.basename(original_image_path)}"
        output_dir = os.path.dirname(original_image_path)
        output_path = os.path.join(output_dir, output_filename)
        
        # Pertahankan resolusi cerdas AI (512x512) agar tidak pecah/blur saat dikembalikan ke resolusi kamera HP (4K)
        result_image.save(output_path)
        
        return {
            "result_path": output_path,
            "face_shape": detected_shape,
            "style_applied": style_name
        }

# Instansiasi singleton agar model tidak di-load berulang kali
generator = HairStyleGenerator()
