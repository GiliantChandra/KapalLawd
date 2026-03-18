import os
import torch
import cv2
import numpy as np
from PIL import Image

# Catatan: Ini adalah modul inti tempat AI model berjalan (GPU Accelerated).
# Kita akan menggunakan Diffusers (Stable Diffusion Inpainting) atau IP-Adapter.

class HairStyleGenerator:
    def __init__(self):
        print("Memuat model AI ke GPU RTX 3050...")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Device yang digunakan: {self.device}")
        
        # Placeholder untuk inisialisasi pipeline model HuggingFace
        # self.pipeline = StableDiffusionInpaintPipeline.from_pretrained(...)
        # self.pipeline.to(self.device)
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
        
        # 2. Proses Inpainting dengan Prompt (style_name) atau Image Prompt (IP-Adapter)
        # original_pil = Image.open(original_image_path).convert("RGB")
        # target_pil = Image.open(target_style_image_path).convert("RGB")
        
        # ... Proses Generator VRAM RTX 3050 Berjalan ...
        # result_image = self.pipeline(prompt=f"A hyperrealistic photo of a person with {style_name} hairstyle", image=original_pil, mask_image=mask_image).images[0]
        
        # 3. Simpan hasil sementara
        output_filename = f"result_{os.path.basename(original_image_path)}"
        output_dir = os.path.dirname(original_image_path)
        output_path = os.path.join(output_dir, output_filename)
        
        # [KODE SEMENTARA]: Salin foto original menjadi grayscale sebagai tanda "Telah diproses"
        img = cv2.imread(original_image_path)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        cv2.imwrite(output_path, gray)
        
        return output_path

# Instansiasi singleton agar model tidak di-load berulang kali
generator = HairStyleGenerator()
