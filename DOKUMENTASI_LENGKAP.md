# 📖 DOKUMENTASI LENGKAP — StyleSense AI (KapalLawd)

> Dokumen ini menjelaskan **seluruh komponen proyek** dari level konseptual hingga implementasi kode secara mendalam.

---

## 🗂️ DAFTAR ISI

1. [Gambaran Umum Proyek](#1-gambaran-umum-proyek)
2. [Struktur File Proyek](#2-struktur-file-proyek)
3. [Arsitektur Sistem — Bagaimana Semua Terhubung](#3-arsitektur-sistem--bagaimana-semua-terhubung)
4. [Flutter App — Layer Antarmuka Pengguna](#4-flutter-app--layer-antarmuka-pengguna)
   - [main.dart & AuthGate](#41-maindart--authgate)
   - [auth_page.dart — Login & Registrasi](#42-auth_pagedart--login--registrasi)
   - [home_page.dart — Dashboard Utama](#43-home_pagedart--dashboard-utama)
   - [catalog_page.dart — Katalog Gaya Rambut](#44-catalog_pagedart--katalog-gaya-rambut)
   - [capture_page.dart — Kamera & Kirim ke AI](#45-capture_pagedart--kamera--kirim-ke-ai)
   - [result_page.dart — Tampil Hasil AI](#46-result_pagedart--tampil-hasil-ai)
   - [history_page.dart — Riwayat Generasi](#47-history_pagedart--riwayat-generasi)
5. [Firebase — Infrastruktur Cloud](#5-firebase--infrastruktur-cloud)
   - [Firebase Authentication](#51-firebase-authentication)
   - [Cloud Firestore](#52-cloud-firestore)
6. [Backend AI — Google Colab Server](#6-backend-ai--google-colab-server)
   - [server_colab.py](#61-server_colabpy)
   - [ai_engine.py](#62-ai_enginepy)
7. [Cara Kerja Stable Diffusion Inpainting](#7-cara-kerja-stable-diffusion-inpainting)
8. [Cara Kerja Deteksi Bentuk Wajah (MediaPipe + TensorFlow)](#8-cara-kerja-deteksi-bentuk-wajah-mediapipe--tensorflow)
9. [Sistem Masking — Melindungi Wajah, Mengubah Rambut](#9-sistem-masking--melindungi-wajah-mengubah-rambut)
10. [Sistem Prompt Engineering](#10-sistem-prompt-engineering)
11. [AI Recommendation — Mode Otomatis](#11-ai-recommendation--mode-otomatis)
12. [Alur Data Lengkap End-to-End](#12-alur-data-lengkap-end-to-end)
13. [Cara Menjalankan Proyek](#13-cara-menjalankan-proyek)
14. [Katalog Gaya Rambut](#14-katalog-gaya-rambut)

---

## 1. Gambaran Umum Proyek

**StyleSense AI** adalah aplikasi mobile berbasis Flutter yang memungkinkan pengguna **mencoba gaya potongan rambut secara virtual** menggunakan kecerdasan buatan.

Pengguna cukup mengambil foto selfie, memilih gaya rambut dari katalog, lalu aplikasi akan mengirim foto ke server AI di Google Colab. Server tersebut menggunakan **Stable Diffusion Inpainting** untuk "melukis ulang" hanya area rambut di foto, menghasilkan foto baru dengan gaya rambut yang dipilih, tanpa mengubah wajah asli pengguna.

### Teknologi Utama yang Digunakan
| Komponen | Teknologi |
|---|---|
| Aplikasi Mobile | Flutter (Dart) |
| Autentikasi | Firebase Authentication |
| Database | Cloud Firestore |
| AI Generatif | Stable Diffusion v1.5 Inpainting |
| Deteksi Wajah | MediaPipe Face Mesh |
| Klasifikasi Bentuk Wajah | TensorFlow Keras (.h5 model) |
| Server AI | Google Colab (GPU NVIDIA T4) |
| Terowongan Publik | Localtunnel |
| Konfigurasi Remote | Cloud Firestore (config/api/url) |

---

## 2. Struktur File Proyek

```
KapalLawd/
│
├── app/                          ← Proyek Flutter (Aplikasi Android/iOS)
│   ├── lib/
│   │   ├── main.dart             ← Entry point, AuthGate
│   │   ├── firebase_options.dart ← Konfigurasi koneksi Firebase
│   │   └── pages/
│   │       ├── auth_page.dart        ← Login & Sign Up
│   │       ├── home_page.dart        ← Dashboard utama
│   │       ├── catalog_page.dart     ← Grid 8 gaya rambut
│   │       ├── capture_page.dart     ← Kamera, kirim ke AI, simpan hasil
│   │       ├── result_page.dart      ← Tampilkan foto hasil AI
│   │       └── history_page.dart     ← Riwayat semua generasi
│   └── assets/katalog/           ← Foto thumbnail gaya rambut
│       ├── bald.jpg
│       ├── edgar_cut.jpg
│       ├── french_crop.jpg
│       ├── low_fade.jpg
│       ├── warrior_cut.jpg
│       ├── mullet.jpg
│       ├── side_part.jpg
│       └── taper_fade.jpg
│
├── backend/                      ← Server AI Python
│   ├── server_colab.py           ← FastAPI server, endpoint HTTP
│   ├── ai_engine.py              ← Inti logika AI (SD, masking, prompt)
│   ├── face_shape_hybrid_classifier.h5  ← Model TensorFlow pre-trained
│   ├── train_face_shape_classifier.py   ← Script training model (referensi)
│   └── requirements.txt          ← Daftar library Python yang dibutuhkan
│
└── docs/                         ← Dokumentasi tambahan
```

---

## 3. Arsitektur Sistem — Bagaimana Semua Terhubung

Berikut gambaran besar bagaimana setiap komponen berkomunikasi:

```
┌──────────────────────────────────────────────────────────────┐
│                    PENGGUNA (HP Android)                     │
│                                                              │
│   Flutter App ◄──────────────────────────────────┐          │
│       │                                           │          │
│       │ Sign Up / Login          Simpan riwayat   │          │
│       ▼                         baca riwayat      │          │
│  ┌─────────────┐                                  │          │
│  │   Firebase  │                                  │          │
│  │    Auth     │                                  │          │
│  └─────────────┘                                  │          │
│       │                                           │          │
│       │ Verifikasi email UID                      │          │
│       ▼                                           │          │
│  ┌────────────────┐                               │          │
│  │  Cloud Firestore│                              │          │
│  │  - users/      │ ◄─── Simpan/Baca History ─── │          │
│  │  - config/api/ │ ◄─── Baca URL Server Colab ──┘          │
│  └────────────────┘                                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
              │
              │ HTTP POST (foto + styleName)
              │ via URL dari Firestore config/api/url
              ▼
┌─────────────────────────────────────────────────┐
│          GOOGLE COLAB (Nvidia T4 GPU)            │
│                                                  │
│  server_colab.py (FastAPI)                       │
│       │                                          │
│       │ Panggil ai_engine.py                     │
│       ▼                                          │
│  ai_engine.py                                    │
│  ┌─────────────────────────────────────────┐     │
│  │  1. Pre-process foto (resize 512x512)   │     │
│  │  2. MediaPipe → deteksi 468 titik wajah │     │
│  │  3. TensorFlow → klasifikasi face shape │     │
│  │  4. Buat MASK (helm rambut putih)       │     │
│  │  5. Build PROMPT teks untuk SD          │     │
│  │  6. Stable Diffusion Inpainting         │     │
│  │     → Hasilkan foto rambut baru         │     │
│  │  7. Encode ke Base64 → kirim balik      │     │
│  └─────────────────────────────────────────┘     │
│                                                  │
└─────────────────────────────────────────────────┘
              │
              │ HTTP Response (JSON: base64 image + face_shape + style_applied)
              ▼
       Flutter App → Decode → Simpan ke HP → Tampilkan
```

---

## 4. Flutter App — Layer Antarmuka Pengguna

### 4.1 `main.dart` & AuthGate

`main.dart` adalah pintu masuk utama aplikasi. Yang paling penting di dalamnya adalah kelas `AuthGate`.

**Cara kerjanya:**
`AuthGate` berlangganan ke *stream* `FirebaseAuth.instance.userChanges()`. Stream ini secara real-time memberitahu aplikasi setiap kali status login pengguna berubah.

```dart
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.userChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      // Ada pengguna yang login
      if (!user.emailVerified) {
        return HalamanTungguVerifikasi(); // Belum klik link email
      }
      return HomePage(); // Sudah terverifikasi → masuk!
    }
    return AuthPage(); // Belum login → halaman login
  }
)
```

**Kenapa pakai `userChanges()` bukan `authStateChanges()`?**
Karena `userChanges()` juga merefresh saat `user.reload()` dipanggil — ini dibutuhkan saat pengguna menekan tombol "Saya Sudah Verifikasi" dan kita memaksa cek ulang status email.

---

### 4.2 `auth_page.dart` — Login & Registrasi

Satu halaman yang menangani dua mode: **Login** dan **Sign Up**, diswitch dengan variabel `isLogin`.

#### Alur Sign Up:
1. Pengguna isi Nama, Email, Password, Konfirmasi Password
2. Validasi lokal dijalankan:
   - Password min 6 karakter, harus ada huruf besar, dan simbol
   - Konfirmasi password harus cocok
3. `FirebaseAuth.createUserWithEmailAndPassword()` dipanggil → UID dibuat
4. Data Nama & Email disimpan ke Firestore collection `User` dengan key = UID pengguna
5. `sendEmailVerification()` mengirim email berisi tautan ke inbox pengguna
6. `FirebaseAuth.signOut()` dipanggil paksa → pengguna tidak bisa langsung masuk
7. Pengguna harus klik link di email dulu sebelum bisa login

#### Alur Login:
1. Pengguna isi Email + Password
2. `signInWithEmailAndPassword()` dipanggil
3. **Cek kritis:** `userCredential.user!.emailVerified` dicek — jika false, langsung `signOut()` paksa dan tampilkan pesan error
4. Jika email sudah terverifikasi → stream `userChanges()` di `AuthGate` terpicu → pengguna masuk ke `HomePage`

---

### 4.3 `home_page.dart` — Dashboard Utama

Halaman setelah login berhasil. Menampilkan sapaan dan dua pilihan mode:

| Tombol | Tujuan | Data yang dikirim |
|---|---|---|
| **Hairstyle Catalog** | → `CatalogPage` | - |
| **AI Recommendation** | → `CapturePage` | `styleName = "AI_RECOMMENDATION"` |

AppBar memiliki dua ikon:
- 🕐 **History** → navigasi ke `HistoryPage`
- 🚪 **Logout** → `FirebaseAuth.signOut()` → stream AuthGate mendeteksi → kembali ke `AuthPage`

---

### 4.4 `catalog_page.dart` — Katalog Gaya Rambut

Menampilkan grid 8 gaya rambut dari list yang sudah didefinisikan:

```dart
final List<Map<String, String>> hairstyles = [
  {'name': 'Bald',        'image': 'assets/katalog/bald.jpg'},
  {'name': 'Edgar Cut',   'image': 'assets/katalog/edgar_cut.jpg'},
  {'name': 'French Crop', 'image': 'assets/katalog/french_crop.jpg'},
  {'name': 'Low Fade',    'image': 'assets/katalog/low_fade.jpg'},
  {'name': 'Warrior Cut', 'image': 'assets/katalog/warrior_cut.jpg'},
  {'name': 'Mullet',      'image': 'assets/katalog/mullet.jpg'},
  {'name': 'Side Part',   'image': 'assets/katalog/side_part.jpg'},
  {'name': 'Taper Fade',  'image': 'assets/katalog/taper_fade.jpg'},
];
```

Saat pengguna mengetuk satu gaya, ia navigasi ke `CapturePage` dengan membawa `styleName` dan `catalogImagePath` (untuk referensi visual).

---

### 4.5 `capture_page.dart` — Kamera & Kirim ke AI

Inilah halaman paling kritis dalam aplikasi. Ia menangani:

1. **Ambil foto** dari kamera atau galeri menggunakan `image_picker`
2. **Tampilkan preview** foto yang dipilih
3. Saat tombol generate ditekan:

#### Langkah detail di `_generateHaircut()`:
```
a. Cek user login (ambil UID dari FirebaseAuth)
b. Baca URL server dari Firestore: collection('config').doc('api').get()
   → field 'url' (mis: https://xxxxx.loca.lt/generate-hairstyle)
   → .trim() untuk mencegah karakter newline tersembunyi
c. Buat HTTP Multipart POST Request:
   - Header 'Bypass-Tunnel-Reminder': 'true'  ← Menembus filter Localtunnel
   - Header 'User-Agent': 'KapalLawd-Mobile'
   - Field 'user_id': UID Firebase
   - Field 'style_name': nama gaya (mis: "Edgar Cut")
   - File 'image': foto selfie
d. Tunggu respons JSON dari server Colab
e. Decode Base64 → simpan sebagai file .jpg di storage HP
f. Simpan path lokal + styleName + faceShape ke Firestore
   (dengan timeout 2 detik agar tidak blocking)
g. Navigasi ke ResultPage
```

**Kenapa URL dari Firestore?**
URL Localtunnel berubah setiap kali Colab di-restart. Dengan menyimpan URL di Firestore, URL bisa diubah dari browser tanpa perlu rebuild APK.

---

### 4.6 `result_page.dart` — Tampil Hasil AI

Menerima data dari `CapturePage`:
- `styleName` — nama gaya yang diterapkan
- `faceShape` — bentuk wajah yang terdeteksi (mis: "Oval")
- `originalImage` — file foto asli
- `imageUrl` — path lokal file hasil AI

Menampilkan foto hasil dengan `InteractiveViewer` (bisa di-zoom hingga 4x), info bentuk wajah, dan nama gaya yang diterapkan.

Dua tombol aksi:
- **Try Another Photo** → kembali ke CatalogPage
- **Save & Finish** → kembali ke HomePage (foto sudah otomatis tersimpan di HP)

---

### 4.7 `history_page.dart` — Riwayat Generasi

Membaca data dari Firestore secara **real-time** menggunakan `StreamBuilder`:

```
Firestore path: users/{uid}/history
Diurutkan: createdAt descending (terbaru di atas)
```

Setiap kartu menampilkan:
- Thumbnail foto hasil AI (dari path lokal HP menggunakan `Image.file()`)
- Nama gaya yang diterapkan

Saat kartu diketuk → dialog fullscreen dengan `InteractiveViewer` (bisa zoom & pan).

**Catatan penting:** Foto disimpan **lokal di HP**, bukan di Firebase Storage. Ini sengaja untuk menghemat biaya. Konsekuensinya: foto tidak akan tampil di HP lain (karena path lokalnya berbeda).

---

## 5. Firebase — Infrastruktur Cloud

### 5.1 Firebase Authentication

Firebase Auth menangani seluruh sistem login tanpa perlu menyimpan password di server sendiri.

**Cara kerjanya di balik layar:**
- Saat `createUserWithEmailAndPassword()` dipanggil → Firebase membuat akun baru dengan UID unik
- Firebase menyimpan hash password di server Google (kita tidak pernah melihat password aslinya)
- `sendEmailVerification()` menggunakan SMTP internal Firebase untuk mengirim email
- `signInWithEmailAndPassword()` memverifikasi password dan mengembalikan token JWT
- Token JWT ini dipakai oleh Firestore Security Rules untuk memvalidasi akses

### 5.2 Cloud Firestore

Firestore adalah database NoSQL berbasis dokumen yang digunakan untuk 3 hal:

#### Collection `User` — Data pengguna
```
User/
  {uid}/
    Email: "pengguna@gmail.com"
    Nama: "Nama Pengguna"
    createdAt: Timestamp
```

#### Collection `users` — Riwayat generasi
```
users/
  {uid}/
    history/
      {docId}/          ← auto-generated ID
        styleName: "Edgar Cut"
        faceShape: "Oval"
        resultImageUrl: "/data/user/0/.../ai_result_1234.jpg"  ← path lokal HP
        createdAt: Timestamp (server)
```

#### Collection `config` — URL dinamis server AI
```
config/
  api/
    url: "https://mean-parrots-calm.loca.lt/generate-hairstyle"
```

**Cara memperbarui URL:** Buka Firebase Console → Firestore → config → api → edit field `url` → paste URL Localtunnel terbaru.

---

## 6. Backend AI — Google Colab Server

### 6.1 `server_colab.py`

File ini menjalankan server HTTP menggunakan **FastAPI** + **Uvicorn** di dalam Google Colab.

**Alur startup:**
```python
generator = None  # Default aman — tidak crash jika loading gagal

try:
    import ai_engine
    generator = ai_engine.get_generator()  # Load semua model AI
    print("✅ AI Engine Siaga 100%!")
except Exception as e:
    startup_error = str(e)  # Simpan pesan error untuk diagnostik
```

**Kenapa `generator = None` dulu?**
Jika loading model gagal (mis: kehabisan RAM/GPU), variabel `generator` tetap terdefinisi sebagai `None`. Tanpa ini, endpoint akan crash dengan error "name 'generator' is not defined" yang membingungkan.

**Endpoint utama:**
```
POST /generate-hairstyle
Content-Type: multipart/form-data
Fields:
  - user_id: string
  - style_name: string
  - image: file (JPEG/PNG)

Response:
{
  "image_base64": "...",
  "face_shape": "Oval",
  "style_applied": "Edgar Cut"
}
```

**Cara menjalankan di Colab:**
```python
from google.colab import drive
drive.mount('/content/drive')

# Upload server_colab.py, ai_engine.py, face_shape_hybrid_classifier.h5

!pip install -r requirements.txt
!python server_colab.py &  # Jalankan di background

# Di cell terpisah:
!npx localtunnel --port 8000  # Buat URL publik
# Salin URL yang muncul → update ke Firestore config/api/url
```

---

### 6.2 `ai_engine.py`

Inti dari seluruh kecerdasan aplikasi. Kelas `AdvancedHairStyleGenerator` dimuat sekali saat startup dan digunakan berulang kali (Singleton Pattern).

**Komponen yang dimuat saat startup:**
1. **MediaPipe Face Mesh** — library ringan untuk mendeteksi 468 titik koordinat wajah
2. **TensorFlow Model (.h5)** — model buatan sendiri untuk mengklasifikasi bentuk wajah
3. **Stable Diffusion Inpainting Pipeline** — model AI generatif utama (±2GB VRAM)

---

## 7. Cara Kerja Stable Diffusion Inpainting

Stable Diffusion adalah model AI generatif yang bisa "menggambar" gambar dari deskripsi teks. Versi **Inpainting** khusus dirancang untuk mengedit *bagian tertentu* dari foto yang sudah ada.

### Konsep Dasar: Difusi (Diffusion)

Stable Diffusion bekerja dengan proses 2 tahap:

**Tahap FORWARD (Training):** Ambil foto nyata → tambahkan noise (kebisingan) secara bertahap hingga menjadi gambar acak sepenuhnya. Model belajar "seperti apa noise di setiap langkah."

**Tahap REVERSE (Generasi):** Mulai dari gambar noise acak → model secara bertahap menghapus noise, dipandu oleh deskripsi teks (prompt), hingga terbentuk gambar yang bermakna.

### Cara Kerja Inpainting Khusus

Untuk inpainting, prosesnya ditambah satu elemen: **masker**.

```
Input:
  - Foto asli (512x512)
  - Masker (hitam-putih):
      PUTIH = "Area ini boleh AI ubah"
      HITAM = "Area ini DILINDUNGI, jangan disentuh"
  - Prompt teks: "Edgar Cut haircut, blunt horizontal fringe..."

Proses:
  1. Area PUTIH di foto asli diacak dengan noise (strength=0.92)
     → Semakin tinggi strength, semakin banyak noise yang ditambahkan
     → 0.92 berarti AI "melupakan" ~92% informasi asli di area putih
  2. Area HITAM dipertahankan persis seperti aslinya
  3. Model menjalankan 35 langkah denoising (num_inference_steps=35)
     → Setiap langkah, model mengurangi noise sedikit demi sedikit
     → Dipandu oleh prompt dengan guidance_scale=9.5
     → guidance_scale tinggi = lebih patuh ke prompt, kurang kreatif
  4. Result: area putih digambar ulang dengan konten baru sesuai prompt
     area hitam tetap persis seperti foto asli

Output:
  - Foto baru: wajah asli tetap + rambut baru sesuai prompt
```

### Mengapa `runwayml/stable-diffusion-inpainting`?

Model ini dipilih karena:
- Versi 1.5 (SD 1.5) — lebih ringan dari SD 2.x, cocok untuk GPU T4 di Colab
- Khusus dilatih untuk inpainting — lebih akurat dibanding menggunakan SD biasa dengan masker
- Mendukung `torch_dtype=float16` — menghemat 50% VRAM dibanding float32

---

## 8. Cara Kerja Deteksi Bentuk Wajah (MediaPipe + TensorFlow)

Deteksi bentuk wajah dilakukan dalam 2 lapisan:

### Lapisan 1: MediaPipe Face Mesh

MediaPipe adalah library dari Google yang menjalankan deteksi wajah secara real-time. `FaceMesh` mendeteksi **468 titik landmark** di wajah (mata, hidung, mulut, kontur wajah, dll).

```python
results = self.face_mesh.process(rgb_image)
landmarks = results.multi_face_landmarks[0].landmark
# Setiap landmark punya: lm.x, lm.y, lm.z (koordinat 0.0 - 1.0)
```

Dari 468 landmark ini, kita bisa menghitung:
- `face_width` = jarak landmark paling kiri ke paling kanan
- `face_height` = jarak landmark paling atas ke paling bawah
- `center_x`, `center_y` = titik tengah wajah

### Lapisan 2: Model TensorFlow Hybrid

Model `.h5` yang sudah dilatih sebelumnya mengambil **2 input sekaligus**:

**Input 1 — Gambar (224x224 piksel):**
Foto wajah di-resize ke 224x224 dan dinormalisasi (nilai piksel dibagi 255 → range 0.0-1.0). Diproses oleh lapisan convolutional untuk mengekstrak fitur visual bentuk wajah.

**Input 2 — Koordinat Landmark (300 angka):**
100 landmark pertama diambil, masing-masing punya koordinat x, y, z → 300 angka. Ini memberi model informasi geometris presisi tentang proporsi wajah.

**Output:** Vektor probabilitas 5 kelas:
```
['Oval', 'Round', 'Square', 'Heart', 'Oblong']
```
Kelas dengan nilai tertinggi (`argmax`) adalah bentuk wajah yang terdeteksi.

**Fallback:** Jika model `.h5` tidak ada atau gagal load → `detected_shape` tetap `"Oval"` (default paling aman karena oval cocok dengan hampir semua gaya rambut).

---

## 9. Sistem Masking — Melindungi Wajah, Mengubah Rambut

Masking adalah komponen paling kritis. Masker yang buruk = wajah berubah menjadi orang lain.

### Cara Membuat Masker

```
Langkah 1: Mulai dengan kanvas HITAM (400x400)
           → Berarti: tidak ada yang boleh diubah AI

Langkah 2: Gambar ELIPS PUTIH di atas kepala ("Helm Rambut")
           Pusatnya: center_x, hair_center_y (30% di atas center wajah)
           Ukuran: 95% lebar wajah × 90% tinggi wajah
           → Ini adalah area di mana AI boleh melukis rambut baru

Langkah 3: Gambar ELIPS HITAM di tengah, tepat di atas wajah
           Pusatnya: center_x, center_y (tepat center wajah)
           Ukuran: 55% lebar wajah × 50% tinggi wajah
           → Menimpa kembali area wajah → wajah terlindungi

Langkah 4: Gaussian Blur (31x31 piksel)
           → Membuat tepi masker menjadi gradasi abu-abu
           → Mencegah batas keras antara area asli dan area AI
           → Zona blur ±15px = zona pengaruh parsial AI (bukan 0% atau 100%)
```

**Visualisasi Masker:**
```
■■■■■■■■■■■■■■■■■■■■■
■■■■■■□□□□□□□□■■■■■■   □ = PUTIH (AI boleh ubah = Area Rambut)
■■■■□□□□□□□□□□□□■■■■   ■ = HITAM (Terlindungi = Background)
■■■□□□□□■■■■□□□□□■■■   ░ = ABU (Zona transisi blur)
■■■□□□■■■■■■■■□□□■■■
■■■□□□■■WAJAH■■□□□■■■   █ = HITAM di tengah (Wajah terlindungi)
■■■□□□■■■■■■■■□□□■■■
■■■□□□■■■■■■■■□□□■■■
■■■■□□□□□□□□□□□□■■■■
■■■■■■■□□□□□□□■■■■■■
■■■■■■■■■■■■■■■■■■■■■
```

### Tradeoff Blur

| Blur Radius | Keuntungan | Kekurangan |
|---|---|---|
| Kecil (11px) | Batas tajam, wajah lebih aman | Sambungan terlihat kasar/patah |
| Sedang (31px) | Sambungan halus | Zona abu-abu ±15px di tepi wajah |
| Besar (51px) | Sangat halus | AI bisa sedikit mempengaruhi dahi/alis |

Saat ini menggunakan **31px** sebagai kompromi.

---

## 10. Sistem Prompt Engineering

Prompt adalah "kalimat perintah" yang diberikan ke Stable Diffusion. Kualitas prompt sangat menentukan kualitas hasil.

### Struktur Prompt (Urutan Kritis!)

SD 1.5 memberikan **bobot lebih tinggi pada token di awal prompt**. Oleh karena itu:

```
URUTAN 1 → DESKRIPSI GAYA (Bobot 1.7x) — PALING PENTING
"{style_description}"

URUTAN 2 → NAMA GAYA (Bobot 1.6x)
"(perfect {clean_style} haircut:1.6)"

URUTAN 3 → SUBJEK & KUALITAS
"portrait of a handsome man, clean masculine face..."

URUTAN 4 → ATURAN BENTUK WAJAH
"tall volume on top, very tight sides, elongating the face..."

URUTAN 5 → KUALITAS TEKNIS
"(8k resolution), (professional photography)..."
```

### Deskripsi Per Gaya (style_map)

Setiap gaya punya deskripsi spesifik yang dirancang untuk melawan bias SD:

| Gaya | Deskripsi Kunci |
|---|---|
| Bald | "no hair at all, smooth shiny scalp, no stubble" |
| Warrior Cut | "long hair on top, shaved sides, viking aesthetic" |
| Edgar Cut | "BLUNT HORIZONTAL straight fringe, NOT angled NOT side swept" |
| French Crop | "fringe falling STRAIGHT FORWARD, NOT swept to any side" |
| Side Part | "SIDE PART on left, hair combed to the RIGHT" |
| Low Fade | "fade ONLY at the very bottom near ears and neck" |
| Taper | "clean taper at temples and neckline ONLY" |
| Mullet | "SHORT on top, VERY LONG at the back of the neck" |
| Faux Hawk | "CENTRAL RAISED RIDGE, NOT to the side" |

### Negative Prompt

Negative prompt memberi tahu AI apa yang **dilarang** muncul di gambar:

```
Anti-bias sisiran (PALING PENTING):
(hair swept to side:1.6), (side swept hair:1.6),
(hair combed left:1.5), (hair combed right:1.5)

Anti-distorsi:
(bad anatomy, deformed face), (extra fingers, missing fingers),
(bad hair, floating hair, disconnected hair)

Anti-kualitas rendah:
(low quality, worst quality, blurry, pixelated)

Anti-non-realis:
(anime, cartoon, cgi, render, illustration)
```

**Kenapa bias "sisir ke kiri atas"?**
SD 1.5 dilatih dari miliaran foto internet. Mayoritas foto pria di internet menampilkan rambut disisir ke samping (side swept). Tanpa negative prompt yang eksplisit, SD selalu "jatuh" ke pilihan paling statistis — yaitu rambut disisir ke samping.

---

## 11. AI Recommendation — Mode Otomatis

Saat pengguna memilih "AI Recommendation" di `HomePage`, `styleName = "AI_RECOMMENDATION"` dikirim ke server.

Di `ai_engine.py`, interceptor menangkap ini:

```python
if style_name == "AI_RECOMMENDATION":
    recommendation_map = {
        'Oval':   'Warrior Cut',
        'Round':  'Edgar Cut',
        'Square': 'Bald',
        'Heart':  'Side Part',
        'Oblong': 'Taper Fade'
    }
    applied_style = recommendation_map.get(detected_shape, 'Taper Fade')
```

**Logika di balik rekomendasi:**

| Bentuk Wajah | Rekomendasi | Alasan |
|---|---|---|
| Oval | Warrior Cut | Wajah oval cocok dengan hampir semua gaya; Warrior Cut menonjolkan keseimbangan |
| Round | Edgar Cut | Fringe lurus horizontal membuat wajah bulat terlihat lebih panjang |
| Square | Bald | Wajah kotak yang tegas sangat cocok dengan kepala botak yang kuat |
| Heart | Side Part | Sisi yang seimbang membantu menyeimbangkan dagu yang sempit |
| Oblong | Taper Fade | Taper yang natural tidak menambah tinggi, mempersingkat kesan wajah panjang |

---

## 12. Alur Data Lengkap End-to-End

Berikut perjalanan data dari klik pengguna hingga foto hasil ditampilkan:

```
1. USER klik "Edgar Cut" di CatalogPage
   └─ Navigator.push(CapturePage(styleName: "Edgar Cut"))

2. USER foto selfie → imageFile tersimpan di memori HP

3. USER klik "Generate" → _generateHaircut() dijalankan

4. Baca URL dari Firestore:
   config/api/url → "https://xxxxx.loca.lt/generate-hairstyle"

5. HTTP Multipart POST dikirim ke URL tersebut:
   body: {user_id, style_name: "Edgar Cut", image: <file>}

6. Localtunnel meneruskan request ke Colab port 8000

7. FastAPI (server_colab.py) menerima request:
   → Simpan file ke /tmp/filename.jpg
   → Panggil generator.generate_hairstyle(uid, "Edgar Cut", "/tmp/...")

8. ai_engine.py bekerja:
   a. Buka foto → koreksi EXIF → resize 512x512 dengan padding hitam
   b. MediaPipe → proses 468 landmark wajah
   c. TensorFlow model → prediksi: "Oval" (misalnya)
   d. Hitung koordinat wajah → buat masker ellips
   e. Build prompt:
      "(BLUNT HORIZONTAL straight fringe...:1.7),
       (perfect Edgar Cut haircut:1.6),
       portrait of a handsome man...
       balanced proportions, natural symmetry..."
   f. Stable Diffusion Inpainting:
      - 35 langkah denoising
      - guidance_scale=9.5
      - strength=0.92
   g. Hasil PIL Image → encode ke Base64 JPEG (quality=90)

9. Server mengembalikan JSON:
   {image_base64: "...", face_shape: "Oval", style_applied: "Edgar Cut"}

10. Flutter menerima response:
    → base64.decode() → tulis ke file /documents/ai_result_1234.jpg
    → Simpan ke Firestore: users/{uid}/history dengan path lokal

11. Navigasi ke ResultPage:
    → Image.file(File(path)) menampilkan foto hasil
    → Tampilkan: "Face Shape: Oval | Applied Style: Edgar Cut"

12. USER klik "Save & Finish" → kembali ke HomePage
    History sudah tersimpan, tampil di HistoryPage via StreamBuilder
```

---

## 13. Cara Menjalankan Proyek

### Prasyarat
- Flutter SDK terinstall
- Android Studio / VS Code
- Akun Google (Firebase + Google Colab)
- HP Android (atau emulator)

### Setup Flutter App

```bash
# 1. Clone atau buka proyek
cd C:\Software\KapalLawd\app

# 2. Install dependencies
flutter pub get

# 3. Pastikan file google-services.json ada di android/app/
# (Unduh dari Firebase Console → Project Settings → Android)

# 4. Build APK
flutter build apk --release

# APK ada di: build/app/outputs/flutter-apk/app-release.apk
```

### Setup Backend di Google Colab

**Cell 1 — Install dependencies:**
```python
!pip install fastapi uvicorn python-multipart diffusers transformers accelerate opencv-python-headless mediapipe tensorflow nest-asyncio
```

**Cell 2 — Upload file dan jalankan server:**
```python
# Upload manual: ai_engine.py, server_colab.py, face_shape_hybrid_classifier.h5
# Klik ikon folder di Colab → drag & drop ketiga file

import subprocess
server_process = subprocess.Popen(['python', 'server_colab.py'])
```

**Cell 3 — Buat URL publik:**
```python
!npx localtunnel --port 8000
# Output: your url is: https://xxxxx.loca.lt
```

**Cell 4 — Update URL di Firestore:**
Salin URL dari Cell 3 → Firebase Console → Firestore → `config` → `api` → edit field `url`.

---

## 14. Katalog Gaya Rambut

| Gaya | Ciri Khas | Bentuk Wajah Terbaik |
|---|---|---|
| **Bald** | Kepala plontos licin tanpa rambut | Square, Oval |
| **Edgar Cut** | Fringe lurus horizontal di dahi, skin fade tinggi | Round, Oblong |
| **French Crop** | Crop pendek, poni ke depan, fade rapi | Round, Oval |
| **Low Fade** | Rambut atas alami, fade hanya di bawah telinga/leher | Semua |
| **Warrior Cut** | Rambut panjang di atas, undercut sisi, kesan Viking | Oval, Heart |
| **Mullet** | Pendek di depan & sisi, sangat panjang di belakang | Oval |
| **Side Part** | Belahan rapi di kiri, sisir ke kanan, kesan profesional | Heart, Oblong |
| **Taper Fade** | Taper alami di pelipis & tengkuk, alami dan rapi | Oblong, Oval |

---

*Dokumentasi ini dibuat berdasarkan kode aktual proyek per April 2026.*
*File: `DOKUMENTASI_LENGKAP.md` — Versi Final*
