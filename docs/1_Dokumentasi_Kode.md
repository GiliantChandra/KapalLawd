# Dokumentasi Kode Proyek KapalLawd (AI Hairstyle)

Proyek ini terbagi menjadi dua basis kode utama: **Aplikasi Mobile (Flutter/Dart)** dan **Server Cerdas (Python/FastAPI)**.

## 1. Aplikasi Mobile (Flutter)
Terletak di folder `app/lib/`. Bertugas sebagai antarmuka (User Interface) dan pengambil gambar (Sensor Kamera).

### A. `main.dart`
- **Tujuan:** Titik awal aplikasi.
- **Logika Utama:** Menginisialisasi koneksi dengan Firebase (`Firebase.initializeApp`) dan mendaftarkan warna/tema aplikasi (Google Fonts). Mengarahkan user ke halaman Login/Home berdasarkan status otentikasi.

### B. `pages/auth_page.dart`
- **Tujuan:** Gerbang keamanan awan.
- **Logika Utama:** Memanfaatkan `FirebaseAuth.instance` untuk login/register menggunakan Email dan Password.

### C. `pages/home_page.dart` & `pages/catalog_page.dart` 
- **Tujuan:** Layar utama dan katalog gaya.
- **Logika Utama:** Menggunakan `SharedPreferences` untuk menyimpan URL Server Python lokal pengguna secara dinamis (sehingga pengguna bisa menyetel IP jaringan LAN pribadi jika berpindah Wi-Fi tanpa rekompilasi program). Membawa payload `styleName` pilihan beralih ke `CapturePage`.

### D. `pages/capture_page.dart` (Inti Aplikasi)
- **Tujuan:** Sensor gambar dan penyambung ke Kecerdasan Buatan.
- **Logika Utama:** 
  1. `_pickImage()`: Membuka sensor kamera depan milik perangkat via pustaka `image_picker`.
  2. `_generateHaircut()`: Mengompresi resolusi file foto dengan kualitas 90, membungkusnya menjadi form MIME `http.MultipartRequest` dan mengirimkannya via HTTP POST ke rute `/generate-hairstyle`.
  3. Menerima kembali beban *bodyBytes* gambar modifikasi AI beserta *Metadata Header* kustom spesifik identifikasi rahwang (seperti bentuk wajah).
  4. Secara otomatis menulis pencatatan riwayat pengguna ke basis data **Firebase Firestore** (Penyimpanan direkayasa hanya mencatat String tautan URL menuju Server Lokal/Laptop dengan alasan menghindari batas kuota *Billing* milik Google Firebase Storage).
  5. Navigasi menuju halaman hasil akhir.

### E. `pages/result_page.dart` & `pages/history_page.dart`
- **Tujuan:** Kanvas pameran hasil render AI.
- **Logika Utama:** Memanggil muatan gambar murni dari *URL Network* laptop Python yang berwujud statis menggunakan `Image.network()`. Seluruh halaman foto kini dilem ke dalam _State_ `InteractiveViewer` yang menginjinkan fitur *Pinch-to-Zoom* hingga rasio 4.0 tingkat tanpa nge-*blur* dalam layar *Fullscreen UI Dialog*.

---

## 2. Server Cerdas AI (Python)
Terletak di folder `backend/`. Dirancang untuk bertumbuh sebagai otak dan GPU Processing menggunakan daya tarik *Nvidia Compute Unified Device Architecture (CUDA)*.

### A. `main.py`
- **Tujuan:** Pelabuhan lalu-lintas API (Application Programming Interface).
- **Logika Utama:** 
  1. Menyekrup gerbang aplikasi web via arsitektur asynchronouos **FastAPI** (`uvicorn`).
  2. Mengimplementasikan pustaka bawaan `StaticFiles` beralias mount `/history`. Titik ini menyulap skrip seonggok aplikasi biasa menjadi jaring infrastruktur *Content Delivery Network (CDN) Hosting Server* untuk menangani beban *hosting* seluruh foto JPG modifikasi kepada internet.
  3. Menyediakan _endpoint URL_ penampung *POST Uploads* pada parameter fungsi `process_hairstyle_request`, yang menyuap paket kepada kecerdasan mandiri, lantas menyusupkan metadata detektor bentuk rahang ke dalam `headersResponse`.

### B. `ai_engine.py` (The Heart)
- **Tujuan:** Otak Kecerdasan Buatan & Matematika Geometri Visual.
- **Komponen Kritis:**
  1. `ImageOps.exif_transpose`: Mengkoreksi orientasi metadata penangkap bawaan Smartphone. Menghapus bug cacat logika detektor miring *90 degrees / Horizontal Sleeping Mode*.
  2. `ImageOps.pad`: Melucuti resolusi gajah (raksasa) perangkat ke limit kotak 512x512 tanpa merusak persentase tulang belulang *aspect ratio* via teknik sabuk layar hitam batas luar (*Letterboxing*).
  3. `cv2.CascadeClassifier`: AI pendeteksi koordinat *Bounding Box* bola mata dan lekuk leher (Iterasi parameter Haarcascade Frontalface).
  4. `cv2.ellipse`: Melukis "Telur Baja Hitam / Ellipse Masking Hitam" yang diposisikan absolut melingkari pipi kiri ke kanan serta rahang hingga batas ubun-ubun agar *identitas asli pengguna* tidak dimutasi oleh AI. Melindungi kanvas seutuhnya dari efek regangan *(Stretched / Melted)*.
  5. `StableDiffusionInpaintPipeline`: Menurunkan prompt teks rahasia (*Conditional Text Pipeline*) yang spesifik diracik sesuai identitas potong rambut kamus (`Mullet, Faux Hawk, dsb`) yang diinjeksikan secara terpusat bersama perpaduan Inpainting Area putih *(Background).* Seluruhnya ditekan dengan skala pengarah gaya *(Guidance Scale) 9.5* demi perintisan karya baru tanpa ampun.
