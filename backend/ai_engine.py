import os
import torch
import cv2
import numpy as np
from PIL import Image
from diffusers import StableDiffusionInpaintPipeline

# Catatan: Ini adalah modul inti tempat AI model berjalan (GPU Accelerated).
# Kita menggunakan Diffusers (Stable Diffusion Inpainting).

class HairStyleGenerator:
    def __init__(self):
        print("Model AI Inpainting sedang dimuat. Harap sabar, proses ini memakan VRAM dan Waktu...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Device AI: {self.device}")
        
        try:
            # Menggunakan model inpainting ringan standar (Akan mengunduh 4GB+ dari HuggingFace pada run pertama)
            self.pipeline = StableDiffusionInpaintPipeline.from_pretrained(
                "runwayml/stable-diffusion-inpainting",
                torch_dtype=torch.float16 if self.device == "cuda" else torch.float32
            )
            self.pipeline.to(self.device)
            
            # Sangat efisien untuk menghemat VRAM RTX 3050 (4GB/8GB)
            self.pipeline.enable_model_cpu_offload()
            
            self.is_loaded = True
            print("====> Model AI KECERDASAN BUATAN BERHASIL AKTIF! <====")
        except Exception as e:
            print(f"Sedang mengunduh / Peringatan Model: {e}")
            self.is_loaded = False

    def build_hair_mask(self, original_image_path: str) -> Image.Image:
        """
        Fungsi ini bertanggung jawab membaca foto wajah asli, 
        mendeteksi area rambut dan dahi pengguna menggunakan MediaPipe/OpenCV, 
        lalu merubah area tersebut menjadi MASK (area putih) untuk area yang akan di-replace AI.
        """
        # TODO: Implementasi MediaPipe Face/Hair Segmentation
        # Untuk saat ini kita kembalikan mask kotak sederhana
        img = cv2.imread(original_image_path)
        h, w = img.shape[:2]
        
        mask = np.zeros((h, w), dtype=np.uint8)
        # Gambaran kasar: buat area tengah agak ke atas menjadi putih (rambut)
        mask[0:int(h/2.5), 0:w] = 255
        
        return Image.fromarray(mask).convert("L")

    def generate(self, original_image_path: str, style_name: str, target_style_image_path: str) -> str:
        """
        Fungsi utama yang dipanggil oleh main.py untuk mengeksekusi AI Processing.
        Mengembalikan path (/lokasi file lokal) foto akhir.
        """
        if not self.is_loaded:
            print("Model AI belum termuat sepenuhnya (Bypass untuk saat ini)")
        
        print(f"Memproses style: {style_name} pada gambar {original_image_path}")
        
        # 1. Buat Masking dari foto original
        mask_image = self.build_hair_mask(original_image_path)
        
        # 2. Proses Inpainting dengan Prompt berbasis style_name
        original_pil = Image.open(original_image_path).convert("RGB")
        # Resize ke 512x512 karena syarat mutlak untuk input model SD v1.5
        original_resized = original_pil.resize((512, 512))
        mask_resized = mask_image.resize((512, 512))
        
        if self.is_loaded:
            print("Memulai komputasi Tensor GPU Inpainting...")
            prompt = f"A photorealistic portrait of an asian person with a very well groomed {style_name} hairstyle, highly detailed, sharp focus, 8k resolution"
            negative_prompt = "deformed, blurry, bad anatomy, bad facial symmetry, artifacts, extra limbs"
            
            # Mengeksekusi generasi (membutuhkan sekitar 10 - 20 detik pada RTX 3050)
            result_image = self.pipeline(
                prompt=prompt, 
                negative_prompt=negative_prompt,
                image=original_resized, 
                mask_image=mask_resized, 
                num_inference_steps=25,
                guidance_scale=7.5
            ).images[0]
        else:
            # Fallback jika model masih gagal dimuat (tetap mengembalikan gambar grayscale dummy)
            print("Model belum termuat. Melewati Inpainting AI yang asli.")
            result_image = original_resized.convert("L")
        
        # 3. Simpan hasil gambar
        output_filename = f"generated_ai_{os.path.basename(original_image_path)}"
        output_dir = os.path.dirname(original_image_path)
        output_path = os.path.join(output_dir, output_filename)
        
        # Kembalikan ke ukuran asli atau biarkan 512
        result_image.save(output_path)
        
        return output_path

# Instansiasi singleton agar model tidak di-load berulang kali
generator = HairStyleGenerator()
