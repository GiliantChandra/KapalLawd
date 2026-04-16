import os
import io
import base64
import torch
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from PIL import Image, ImageOps
from diffusers import StableDiffusionInpaintPipeline

class AdvancedHairStyleGenerator:
    def __init__(self):
        print("Membangkitkan Mesin AI Super Cepat...")
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

        # 2. Penebak Bentuk Muka (TensorFlow .h5)
        self.face_shape_model = self._load_face_shape_classifier()

        # 3. Stable Diffusion Inpainting Pipeline
        try:
            self.inpainting_pipeline = StableDiffusionInpaintPipeline.from_pretrained(
                "runwayml/stable-diffusion-inpainting",
                torch_dtype=torch.float16,
                safety_checker=None,
                requires_safety_checker=False
            )
            self.inpainting_pipeline.to(self.device)
            self.inpainting_pipeline.enable_attention_slicing()
            self.is_loaded = True
            print("====> GENERATOR RAMBUT AKTIF 100% <====")
        except Exception as e:
            print(f"Bencana Loading Model SD: {e}")
            self.is_loaded = False

    def _load_face_shape_classifier(self):
        """Memuat model hybrid penebak bentuk wajah dari file .h5"""
        try:
            model_path = '/root/face_shape_hybrid_classifier.h5'
            if not os.path.exists(model_path):
                model_path = 'face_shape_hybrid_classifier.h5'
            if os.path.exists(model_path):
                model = tf.keras.models.load_model(model_path)
                print("🧠 [SUCCESS] Otak Hybrid Penebak Wajah Aktif!")
                return model
        except Exception as e:
            print(f"Bencana Loading Penebak Wajah: {e}")
        return None

    def analyze_face_and_mask(self, image: np.ndarray):
        """
        Membuat masking area rambut dan mendeteksi bentuk wajah.
        Return: (PIL mask image, face shape string)
        """
        h, w = image.shape[:2]
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = self.face_mesh.process(rgb_image)

        detected_shape = "Oval"  # Default fallback

        if results.multi_face_landmarks:
            landmarks = results.multi_face_landmarks[0].landmark

            # Deteksi bentuk wajah via model .h5 jika tersedia
            if self.face_shape_model is not None:
                try:
                    img_resized = cv2.resize(rgb_image, (224, 224))
                    img_normalized = img_resized.astype(np.float32) / 255.0
                    img_input = np.expand_dims(img_normalized, axis=0)

                    landmark_features = []
                    for lm in landmarks[:100]:
                        landmark_features.extend([lm.x, lm.y, lm.z])
                    if len(landmark_features) < 300:
                        landmark_features.extend([0.0] * (300 - len(landmark_features)))
                    lm_input = np.expand_dims(np.array(landmark_features), axis=0)

                    predictions = self.face_shape_model.predict([img_input, lm_input], verbose=0)
                    shape_labels = ['Oval', 'Round', 'Square', 'Heart', 'Oblong']
                    detected_shape = shape_labels[np.argmax(predictions[0])]
                    print(f"🧠 [AI VISION] Wajah: {detected_shape} ({np.max(predictions[0])*100:.2f}%)")
                except Exception as e:
                    print(f"⚠️ Penebak wajah gagal: {e}")

            x_coords = [int(l.x * w) for l in landmarks]
            y_coords = [int(l.y * h) for l in landmarks]
            min_x, max_x = max(0, min(x_coords)), min(w, max(x_coords))
            min_y, max_y = max(0, min(y_coords)), min(h, max(y_coords))

            face_width  = max_x - min_x
            face_height = max_y - min_y
            center_x    = min_x + face_width // 2
            center_y    = min_y + face_height // 2

            # Masking: Kanvas hitam → Helm rambut putih → Wajah dilindungi hitam kembali
            mask = np.zeros((h, w), dtype=np.uint8)
            hair_center_y = center_y - int(face_height * 0.3)
            hair_axis_x   = int(face_width  * 0.95)
            hair_axis_y   = int(face_height * 0.9)
            cv2.ellipse(mask, (center_x, hair_center_y), (hair_axis_x, hair_axis_y), 0, 0, 360, 255, -1)

            face_axis_x = int(face_width  * 0.55)
            face_axis_y = int(face_height * 0.5)
            cv2.ellipse(mask, (center_x, center_y), (face_axis_x, face_axis_y), 0, 0, 360, 0, -1)

            mask = cv2.GaussianBlur(mask, (31, 31), 0)
        else:
            # Fallback: wajah tidak terdeteksi → pakai koordinat tengah gambar
            mask = np.zeros((h, w), dtype=np.uint8)
            cv2.ellipse(mask, (w//2, h//2 - int(h*0.2)), (int(w*0.4), int(h*0.4)), 0, 0, 360, 255, -1)
            cv2.ellipse(mask, (w//2, h//2), (int(w*0.25), int(h*0.3)), 0, 0, 360, 0, -1)
            mask = cv2.GaussianBlur(mask, (21, 21), 0)

        return Image.fromarray(mask).convert("L"), detected_shape

    def generate_hairstyle(self, user_id: str, style_name: str, original_image_path: str):
        if not self.is_loaded:
            return {"error": "Mesin Kecerdasan Stable Diffusion Gagal Memuat!"}

        print(f"🚀 Memproses style: {style_name} untuk pengguna {user_id}")

        # 1. Pre-process gambar (koreksi orientasi EXIF + resize 512x512)
        try:
            original_pil = Image.open(original_image_path)
            original_pil = ImageOps.exif_transpose(original_pil).convert("RGB")
            original_resized = ImageOps.pad(original_pil, (512, 512), color=(0,0,0), method=Image.Resampling.LANCZOS)
            img_np  = np.array(original_resized)
            img_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)
        except Exception as e:
            return {"error": f"Gagal membaca foto asli: {e}"}

        # 2. Deteksi wajah + buat masking
        mask_image, detected_shape = self.analyze_face_and_mask(img_bgr)

        # 3. AI Recommendation: tentukan gaya berdasarkan bentuk wajah
        applied_style = style_name
        if style_name == "AI_RECOMMENDATION":
            recommendation_map = {
                'Oval':   'Warrior Cut',
                'Round':  'Edgar Cut',
                'Square': 'Bald',
                'Heart':  'Side Part',
                'Oblong': 'Taper Fade'
            }
            applied_style = recommendation_map.get(detected_shape, 'Taper Fade')
            print(f"🤖 [AI ADVISOR] Wajah {detected_shape} → Rekomendasi: {applied_style}")

        clean_style = applied_style.replace('_', ' ')

        # =========================
        # STYLE DESCRIPTION MAP
        # Diletakkan paling depan di prompt — token awal paling diperhatikan SD!
        # =========================
        style_map = {
            "Bald":     "completely bald head, no hair at all, smooth shiny scalp, razor shaved clean, perfectly bald, no stubble, glossy smooth skin on head",
            "Warrior":  "warrior cut hairstyle, long hair on top pulled back or loose, shaved or very short undercut sides, viking warrior aesthetic, strong masculine look, flowing long hair on crown, dramatic contrast between long top and shaved sides",
            "Mullet":   "80s rock mullet hairstyle, SHORT on top and sides, VERY LONG at the back of the neck flowing down, business in front party in back",
            "Side":     "deliberate SIDE PART on left, hair combed neatly to the RIGHT side, classic professional comb over, clean parting line",
            "French":   "SHORT CROP with fringe falling STRAIGHT FORWARD over forehead, NOT swept to any side, textured messy look, tight skin fade sides",
            "Crop":     "textured SHORT CROP, fringe pointing FORWARD not sideways, short choppy layers, matte natural finish",
            "Edgar":    "BLUNT HORIZONTAL straight fringe cut perfectly across forehead, geometric precision, NOT angled NOT side swept, high skin fade sides",
            "Low Fade": "natural hair direction on top, fade ONLY at the very bottom near ears and neck, NO aggressive combing direction on top",
            "Taper":    "natural hair growth direction, clean taper at temples and neckline only, no forced combing, relaxed natural top styling",
            "Fade":     "styled hair on top with natural direction, smooth gradient fade from skin at bottom to full hair on top",
            "Faux":     "CENTRAL RAISED RIDGE on top, hair pushed UP in center, NOT to the side, tight faded sides, mohawk-like center strip",
        }

        style_description = ""
        for key in style_map:
            if key.lower() in clean_style.lower():
                style_description = style_map[key]
                break

        # =========================
        # PROMPT UTAMA
        # =========================
        prompt = (
            f"({style_description}:1.7), "
            f"(perfect {clean_style} haircut:1.6), "
            f"portrait of a handsome man, clean masculine face, symmetrical face, "
            f"haircut tailored for a {detected_shape.lower()} face shape, "
            f"(photorealistic:1.4), (RAW photo:1.2), "
            f"85mm lens, sharp focus, studio lighting, "
        )

        # Tambahan aturan per bentuk wajah
        face_shape_rules = {
            "Round":  "tall volume on top, very tight sides, elongating the face shape",
            "Square": "soft textured layers, slightly broken fringe, reducing harsh jawline",
            "Oblong": "wider sides, controlled top height, reducing vertical length",
            "Heart":  "balanced sides and back volume, avoiding narrow jaw emphasis",
            "Oval":   "balanced proportions, natural symmetry, clean styling"
        }
        if detected_shape in face_shape_rules:
            prompt += f"{face_shape_rules[detected_shape]}. "

        prompt += (
            "the hairstyle is clearly visible, clean hairline, natural hair texture, "
            "correct hair direction, no random parting, no messy undefined structure. "
            "(high detail skin texture), (sharp hair strands), "
            "(8k resolution), (professional photography), (realistic lighting), (no blur)."
        )

        # =========================
        # NEGATIVE PROMPT
        # =========================
        negative_prompt = (
            "(female, woman, girl), "
            "(anime, cartoon, cgi, render, illustration, painting, drawing), "
            "(low quality, worst quality, blurry, pixelated, jpeg artifacts), "
            "(bad anatomy, deformed face, asymmetrical eyes, disfigured), "
            "(extra fingers, missing fingers, extra limbs), "
            "(bad hair, fake hair, wig, unnatural hair, floating hair), "
            "(disconnected hair, broken hairline), "
            "(overexposed, underexposed, flat lighting), "
            "(text, watermark, logo), "
            "(hair swept to side:1.6), (side swept hair:1.6), "
            "(hair combed left:1.5), (hair combed right:1.5), "
            "(random hair direction:1.5), (messy undefined hairstyle:1.4)"
        )

        # Kontrol panjang rambut per gaya
        if "bald" in clean_style.lower():
            negative_prompt += (
                ", any hair, hair on head, stubble, short hair, long hair, "
                "hairstyle, wig, toupee, hair follicles visible"
            )
        elif "warrior" in clean_style.lower():
            negative_prompt += ", short hair, buzz cut, bald, crew cut, no volume, flat hair"
        elif any(w in clean_style.lower() for w in ['crop', 'edgar', 'fade', 'short']):
            negative_prompt += ", long hair, shoulder length hair, curtain bangs, fluffy hair, medium length hair"
        else:
            negative_prompt += ", bald, shaved head, extremely short hair"

        # =========================
        # INPAINTING
        # =========================
        print("🔥 MEMBAKAR KE DALAM GPU...")
        try:
            result_image = self.inpainting_pipeline(
                prompt=prompt,
                negative_prompt=negative_prompt,
                image=original_resized,
                mask_image=mask_image,
                num_inference_steps=35,
                guidance_scale=9.5,
                strength=0.92
            ).images[0]
        except Exception as e:
            return {"error": f"GPU Overload / Crash Inpainting: {str(e)}"}

        # Encode hasil ke Base64 untuk dikirim ke Flutter
        buffered = io.BytesIO()
        result_image.save(buffered, format="JPEG", quality=90)
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return {
            "image_base64": img_str,
            "face_shape": detected_shape,
            "style_applied": applied_style
        }


# Global Singleton — hanya satu instance per sesi Colab
_generator_instance = None

def get_generator():
    global _generator_instance
    if _generator_instance is None:
        _generator_instance = AdvancedHairStyleGenerator()
    return _generator_instance
