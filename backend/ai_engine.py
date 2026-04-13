import os
import torch
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.models import Model
from PIL import Image, ImageOps
from diffusers import StableDiffusionInpaintPipeline
import json
from typing import List, Dict, dict

class AdvancedHairStyleGenerator:
    def __init__(self):
        print("Membangkitkan Mesin AI Super Cepat (Tanpa DeepLab & Dlib Bloatware)...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Jaringan Terhubung Ke: {self.device}")

        # 1. MediaPipe Face Mesh (Ultra Ringan & Akurat)
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5
        )

        # 2. Penebak Bentuk Bentuk Muka (TensorFlow)
        self.face_shape_model = self._load_face_shape_classifier()

        # 3. Kelenjar Utama: Stable Diffusion
        try:
            # Gunakan versi fp16 untuk menghemat VRAM drastis!
            self.inpainting_pipeline = StableDiffusionInpaintPipeline.from_pretrained(
                "runwayml/stable-diffusion-inpainting",
                torch_dtype=torch.float16, 
                safety_checker=None,
                requires_safety_checker=False
            )
            self.inpainting_pipeline.to(self.device)
            self.inpainting_pipeline.enable_model_cpu_offload()
            self.inpainting_pipeline.enable_attention_slicing()
            self.is_loaded = True
            print("====> GENERATOR RAMBUT AKTIF 100% <====")
        except Exception as e:
            print(f"Bencana Loading Model SD: {e}")
            self.is_loaded = False

    def _load_face_shape_classifier(self):
        """Memuat Otak Spesialis Bentuk Wajah (Hibrida Image + Landmarks)"""
        try:
            model_path = '/root/face_shape_hybrid_classifier.h5'
            if not os.path.exists(model_path):
                model_path = 'face_shape_hybrid_classifier.h5'
            
            if os.path.exists(model_path):
                # Load Full Architecture & Weights dari hasil Training T4 kita
                model = tf.keras.models.load_model(model_path)
                print("🧠 [SUCCESS] Otak Hybrid Penebak Wajah Aktif!")
                return model
        except Exception as e:
            print(f"Bencana Loading Penebak Wajah: {e}")
        return None

    def analyze_face_and_mask(self, image: np.ndarray):
        """
        [SUPER PRESISI] Membuat Masking dan Menebak Bentuk Wajah Sekaligus:
        - Menganalisa 300 titik koordinat dan Gambar ke H5 Dual-Input
        - Mengembalikan object tuple (ImageMask, FaceShapeString)
        """
        h, w = image.shape[:2]
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = self.face_mesh.process(rgb_image)

        # MULAI DENGAN KANVAS PUTIH KOSONG (Semua dilukis ulang)
        mask = np.ones((h, w), dtype=np.uint8) * 255
        detected_shape = "Oval" # Mode Default Cadangan

        if results.multi_face_landmarks:
            landmarks = results.multi_face_landmarks[0].landmark
            
            # =========================================================
            # [BARU] PENEBAKAN BENTUK WAJAH DENGAN OTAK .H5 NYATA
            # =========================================================
            if self.face_shape_model is not None:
                try:
                    # 1. Olah Gambar 224x224 (Input Pintu 1)
                    img_resized = cv2.resize(rgb_image, (224, 224))
                    img_normalized = img_resized.astype(np.float32) / 255.0
                    img_input = np.expand_dims(img_normalized, axis=0)
                    
                    # 2. Olah 300 Kordinat (Input Pintu 2)
                    landmark_features = []
                    for lm in landmarks[:100]:
                        landmark_features.extend([lm.x, lm.y, lm.z])
                    
                    if len(landmark_features) < 300:
                        landmark_features.extend([0.0] * (300 - len(landmark_features)))
                    lm_input = np.expand_dims(np.array(landmark_features), axis=0)
                    
                    # 3. Prediksi Dual Core
                    predictions = self.face_shape_model.predict([img_input, lm_input], verbose=0)
                    shape_labels = ['Oval', 'Round', 'Square', 'Heart', 'Oblong']
                    detected_shape = shape_labels[np.argmax(predictions[0])]
                    print(f"🧠 [AI VISION] Wajah terdeteksi sebagai: {detected_shape} (Akurasi: {np.max(predictions[0])*100:.2f}%)")
                except Exception as e:
                    print(f"⚠️ Peringatan: Otak gagal menebak bentuk wajah: {e}")
            
            # Kordinat Inti Wajah
            x_coords = [int(l.x * w) for l in landmarks]
            y_coords = [int(l.y * h) for l in landmarks]
            
            # Cari Batas Anatomi Tertinggi & Terendah
            min_x, max_x = max(0, min(x_coords)), min(w, max(x_coords))
            min_y, max_y = max(0, min(y_coords)), min(h, max(y_coords))
            
            face_width = max_x - min_x
            face_height = max_y - min_y
            center_x = min_x + face_width // 2
            center_y = min_y + face_height // 2

            # 1. PROTEKSI ANATOMI WAJAH (HITAM) - Bentuk Telur Polos
            axis_x = int(face_width * 0.55)  # Pas menutupi pipi ke pipi
            axis_y = int(face_height * 0.6)  # Menutupi alis ke dagu (biarkan jidat atas putih)
            # Oval Pelindung tepat di wajah tengah
            cv2.ellipse(mask, (center_x, center_y), (axis_x, axis_y), 0, 0, 360, 0, -1)
            
            # 2. PROTEKSI BADAN/BAJU (HITAM) - Agar Stable Diffusion tidak mengganti baju
            # Lindungi semua area dari leher ke bawah
            batas_batas_leher = center_y + int(face_height * 0.65)
            # Buat trapesium pengaman di bahu
            pts = np.array([
                [center_x - int(face_width*1.5), h], 
                [center_x + int(face_width*1.5), h],
                [center_x + axis_x, batas_batas_leher],
                [center_x - axis_x, batas_batas_leher]
            ], np.int32)
            cv2.fillPoly(mask, [pts], 0)

            # Pelembutan Batas (Blur) agar hasil rambut AI dan wajah menyatu sempurna tanpa garis kasar
            mask = cv2.GaussianBlur(mask, (41, 41), 0)
        else:
            # Fallback jika wajah gagal terdeteksi (Gunakan perkiraan rasio)
            cv2.ellipse(mask, (w//2, h//2 + int(h*0.1)), (int(w*0.3), int(h*0.35)), 0, 0, 360, 0, -1)
            cv2.rectangle(mask, (0, h//2 + int(h*0.4)), (w, h), 0, -1)
            mask = cv2.GaussianBlur(mask, (21, 21), 0)

        # Kembalikan Masker KELABU sebagai Objek PIL standard Inpainting
        return Image.fromarray(mask).convert("L"), detected_shape

    def generate_hairstyle(self, user_id: str, style_name: str, original_image_path: str):
        if not self.is_loaded:
            return {"error": "Mesin Kecerdasan Stable Diffusion Gagal Memuat!"}

        print(f"🚀 Memproses style: {style_name} untuk pengguna {user_id}")

        # 1. PRE-PROCESS GAMBAR (Anti Miring + Resolusi 512)
        try:
            original_pil = Image.open(original_image_path)
            original_pil = ImageOps.exif_transpose(original_pil).convert("RGB")
            # Pad & Resize sempurna tanpa Distorsi
            original_resized = ImageOps.pad(original_pil, (512, 512), color=(0,0,0), method=Image.Resampling.LANCZOS)
            
            # Simpan sementara untuk MediaPipe CV2
            img_np = np.array(original_resized)
            img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
        except Exception as e:
            return {"error": f"Gagal membaca foto asli: {e}"}

        # 2. PROSES BENTUK WAJAH DENGAN KECERDASAN BUATAN + MASKING
        mask_image, detected_shape = self.analyze_face_and_mask(img_bgr)

        # 3. MANTRA PROMPT ESTETIK TINGGI
        clean_style = style_name.replace('_', ' ')
        prompt = f"A photorealistic, highly detailed 8k portrait of an attractive man with an absolute perfect {clean_style} haircut fashion. "
        
        # ==============================================================
        # [KUNCI RAHASIA: SINKRONISASI FACE SHAPE & STABLE DIFFUSION]
        # ==============================================================
        prompt += f"The haircut is masterfully tailored by a professional barber to perfectly fit a {detected_shape.lower()} face shape. "

        if "Masterpiece" in clean_style or "AI Auto" in clean_style:
            if detected_shape == "Round":
                prompt += "Adding volume on top and keeping the sides extremely short to visually elongate the round face. "
            elif detected_shape == "Square":
                prompt += "Softening the strong angular jawline with texture and short messy fringes. "
            elif detected_shape == "Oblong":
                prompt += "Adding width to the sides and a flat fringe falling over the forehead to shorten the face length. "
            elif detected_shape == "Heart":
                prompt += "Keeping some length on the sides and back to balance the wide forehead and narrow chin. "
            elif detected_shape == "Oval":
                prompt += "A perfectly balanced proportion showing off the ideal symmetry of the oval face. "
        else:
            # Injeksi Detail Potongan Spesifik Bintang Hollywood (Manual Catalog)
            if "Mullet" in clean_style:
                prompt += "Short messy textured hair on top, extremely long flowing hair on the back of the neck falling down, 80s rock aesthetic. "
            elif "Buzz" in clean_style:
                prompt += "Very short shaved military buzz cut, scalp barely visible, aggressive sharp edges. "
            elif "Middle" in clean_style:
                prompt += "Symmetrical center parted hair, e-boy style curtain bangs falling beautifully over the forehead. "
            elif "Side" in clean_style:
                prompt += "Classic dapper side part comb over, neat and polished business professional hair. "
            elif "French" in clean_style:
                prompt += "Tight skin fade sides, textured flat fringe dropping neatly straight over the forehead, trendy crop. "
            elif "Faux" in clean_style:
                prompt += "Spiky pushed-up punk crest in the middle, clean faded extremely short sides, voluminous faux hawk. "

        prompt += "High end studio lighting, professional photography, hyper-detailed hair strands perfectly attached to scalp, seamless blending."
        # Singkirkan aura mutan dari hasil AI
        negative_prompt = "deformed, ugly, bad anatomy, bad lighting, disconnected hair, floating hair, extra faces, extra ears, crossed eyes, unblended, cartoon, illustration, low resolution, artifacts"

        # 4. PENYEPUHAN TENSOR GPU (Stable Diffusion VRAM Inpainting Magic)
        print("🔥 MEMBAKAR KE DALAM GPU Raksasa CUDA...")
        try:
            result_image = self.inpainting_pipeline(
                prompt=prompt,
                negative_prompt=negative_prompt,
                image=original_resized,
                mask_image=mask_image,
                num_inference_steps=35,  # Resolusi detail ditarik maksimal
                guidance_scale=11.5,     # Skala kekerasan AI untuk memaksa bentuk rambut
                strength=0.99            # DI ATAS 0.99 = Meratakan rambut lama total secara utuh
            ).images[0]
        except Exception as e:
            return {"error": f"GPU Overload / Crash Inpainting: {str(e)}"}

        # 5. KEPULANGAN TERSANDI (Membangkitkan Base64 untuk Flutter)
        import io
        import base64
        buffered = io.BytesIO()
        result_image.save(buffered, format="JPEG", quality=90)
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return {
            "image_base64": img_str,
            "face_shape": detected_shape,
            "style_applied": style_name
        }

# Global Singleton
_generator_instance = None

def get_generator():
    global _generator_instance
    if _generator_instance is None:
        _generator_instance = AdvancedHairStyleGenerator()
    return _generator_instance
