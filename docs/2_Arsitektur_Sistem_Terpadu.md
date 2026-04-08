# Arsitektur Sistem Terpadu KapalLawd AI

Sistem ini didesain sebagai platform hibrida (*Hybrid Application*) antara jalur distribusi Komputasi Awan Lokal (*Edge-Cloud Computing*) sebagai tulang punggung berat (Grafis) dan sinkronisasi awan asli (*Firebase Ecosystem*) sebagai tulang punggung ringan (Database teks) demi mengakali rentetan *Paywall/Billing* dari raksasa teknologi.

## 1. Alur Transmisi Lintasan Data (Workflow Architecture)
Secara runut dan teliti, berikut rekam transmisi satu ketukan tombol pengguna hingga terciptanya foto AI:
1. **[User]** Membuka Applikasi Flutter, memilih rujukan target potongan rambut, dan menjepret wajah di sensor Kamera Depan.
2. **[Flutter]** Menembak koneksi rahasia (*Multipart API HTTP Request*) melintasi Router yang memuat tujuan IP langsung (*Direct IPv4*) ke bilik Laptop pengguna (Port 8000), membawa 2 kargo data: Kumpulan baris bytes Foto `.jpg` dan teks `Target_Gaya_Rambut_String`.
3. **[Python FastAPI]** Menerima kargo, mengalokasikan data ke skrip *Offline AI System* yang bertumpu pada daya hisap listrik dan memori grafis (VRAM) tertutup pada Laptop Anda. Berkecepatan ekstrem selayaknya perusahaan model besar *generative AI* tapi dengan biaya gratis Rp0.
4. **[HuggingFace Diffusers]** Menyulap ruang kosong kanvas menjadi ilustrasi rambut hyper-realistis dengan menanam sel piksel ke dalam berkas direktori `backend/history/`.
5. **[Python FastAPI]** Membalas tembakan paket *Flutter Header Request* dan memberikan pengunguman HTTP 200 OK berisi alamat muatan gambar matang: `"Sukses! Tautan lahir: [id].jpg"`.
6. **[Flutter]** Secara kognitif hanya menyimpan untaian teks `[id].jpg` keekstensi keranjang **Firebase Firestore** tanpa menitipkan beban memorinya kepada Google Cloud—teknik Bypass mutlak agar kuota batas ukuran tidak disentuh.
7. **[Flutter]** Aplikasi membuka layar transisi *Result Page* dan menyedot paksa URL Server Desktop berformat `http://[IP_LAPTOP]:8000/history/[id].jpg` yang diolah secara *streaming network*.

## 2. Mekanika Machine Learning & Pergerakan Stable Diffusion
Pilar tunggal kecerdasan di proyek ini difasilitasi oleh model difusi tingkat akar, **Stable Diffusion Inpainting V1.5 (RunwayML Model)**. 
Guna mengatur watak halusinasi (ketidaktertiban visual AI tingkat tinggi), pendekatan ini berjalan dalam 2 kendali operasi wajib:

### A. Ilmu Masking (Operasi Matematika Geometri Kanvas)
Model Difusi sangat acak nan liar. Untuk memonopoli keliarannya, kita menggembok wilayah melukis secara paksa:
- **Zona Aman Wajib (Wajah, Mata, Bibir)** digembok dengan **Mask Hitam** (Parameter Vektor Radius OpenCV). Perisai dibentuk sedemikian presisi layaknya benteng bentuk Oval (Ellipse) menutupi pipi dan ditumpuk dengan blok penutup bentuk KOTAK panjang dari dagu ke batas pundak dada. Hal ini melindungi postur wajah untuk disalin murni tanpa regresi modifikasi.
- **Zona Bermain Bebas (Ruang Udara Kiri Kanan, Rambut Utama, Langit-langit)** diizinkan diwarna **Mask Putih** (Area 255/Terbuka). Model Diffusion Inpainting akan menggunduli piksel berlumuran putih tersebut sampai rontok lalu merakit ulang jalinan piksel menjadi bentuk mahakarya sesuai kalimat tuntutan dan warna penerangan ruangan *(Studio GQ Background).*

### B. Prompt Engineering (Mantra Kognitif Paksa)
AI diajak berkomunikasi telepatis secara diam-diam oleh Python tanpa perlu diketik oleh Pengguna lewat kerangka kiasan teks otomatis:
* **Positive Prompt Inti Utama:** Selalu disusupkan kalimat pemaksa `"A hyperrealistic, professional front-facing studio portrait... 8k resolution, razor sharp focus, meticulously woven individual strand."`
* **Prompt Pergerakan Model Spesifik:** (Apabila pengguna memilih menu Faux Hawk, Python dengan sendirinya menempelkan kode sisipan *"Hair pushed upwards and spiked in the crest middle, short shaven sides"*). Mengajari AI pola biologi rambut.
* **Negative Prompt Pelindung:** AI ditanamkan ancaman larangan (Mengekang 180 derajat keanehan). Barisan kode negatif ini melindungi gambar jika parameter `strength` melewati ambang batas kesempurnaan. Python melarang `"deformity, extra faces, extra heads, floating unconnected hair, bad strange anatomy, extra eyes, mutants, ugly, deformed, different face"`. Ini menghapuskan ketakutan mutasi *Frankenstein* saat generator kehilangan kendali rujukan struktur.

## 3. Tata Kelola Pemisahan Topologi Database
Proyek dikonversi untuk berefisiensi ekstrem tanpa memerlukan biaya langganan awan Firebase seumur hidup:
- **Di Awan Aether (Firebase Firestore):** Ditugaskan merantai jejak teks relasional Firebase (Authentication/Identifikasi UUID user, dan Rekam tabel waktu penekanan foto). Beroperasi di ekosistem murni awan.
- **Di Besi Lokal (Laptop Static FastAPI):** Bertindak murni sebagai tiang derek file seberat berton-ton layaknya sebuah perusahan *Cloud Storage CDN Hosting Server* asli. Aplikasi Flutter diformat secara parasit guna bertamu ke Laptop Anda setiap saat mencari foto sejarah yang berjejer tertata rapi.
