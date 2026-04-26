# 🎨 Prinsip dan Penerapan IMK — StyleSense AI

Dokumen ini memaparkan penerapan 10 Heuristik Nielsen (prinsip utama Interaksi Manusia dan Komputer) yang diimplementasikan pada antarmuka (UI/UX) aplikasi **StyleSense AI**.

---

## 1. Visibility of System Status (Kejelasan Status Sistem)
Sistem harus selalu memberikan informasi kepada pengguna tentang apa yang sedang terjadi dalam waktu yang wajar.

*   **Penerapan:**
    *   **Step Indicator (Alur Proses):** Di halaman `CapturePage`, terdapat indikator progres 3 langkah ("Pilih Foto" → "Proses AI" → "Lihat Hasil"). Pengguna tahu persis mereka berada di tahap mana.
    *   **Animasi Loading Deskriptif:** Saat tombol "Terapkan Gaya Rambut" ditekan, tombol berubah menjadi tulisan "AI sedang memproses..." dilengkapi animasi berputar (*CircularProgressIndicator*), sehingga pengguna tahu sistem sedang bekerja dan tidak *hang*.
    *   **Badge & Counter:** Menampilkan tulisan "8 gaya tersedia" di katalog dan "X percobaan tersimpan" di riwayat, agar pengguna tahu kapasitas sistem.

## 2. Match Between System and the Real World (Kesesuaian Sistem dengan Dunia Nyata)
Sistem harus berbicara dengan bahasa pengguna, dengan kata-kata, frasa, dan konsep yang akrab bagi pengguna, bukan dengan istilah teknis.

*   **Penerapan:**
    *   **Bahasa yang Konsisten:** Seluruh teks dan tombol dalam aplikasi telah diseragamkan menggunakan Bahasa Indonesia yang natural (contoh: "Masuk", "Daftar", "Katalog", "Riwayat", "Coba Lagi").
    *   **Pesan Error Manusiawi:** Error autentikasi teknis Firebase diubah menjadi bahasa manusia.
        *   *Contoh:* Kode error `invalid-credential` diubah pesannya menjadi *"Email atau password salah. Periksa kembali dan coba lagi"*.
    *   **Sapaan Personal:** Di beranda, pengguna disapa dengan "Halo, [Nama/Email]", memberikan kesan ramah layaknya asisten pribadi di salon sungguhan.

## 3. User Control and Freedom (Kendali dan Kebebasan Pengguna)
Pengguna sering melakukan tindakan secara tidak sengaja dan memerlukan "jalan keluar darurat" yang ditandai dengan jelas tanpa harus melalui proses panjang.

*   **Penerapan:**
    *   **Tombol Navigasi yang Jelas:** Selalu tersedia tombol kembali (panah *back*) di *App Bar* pada setiap halaman.
    *   **Tombol "Tutup" Interaktif:** Pada dialog *preview* gambar berukuran besar di layar `HistoryPage`, disediakan tombol ikon 'X' di sudut untuk menutup tanpa harus menggunakan tombol kembali di HP.
    *   **Tombol "Ganti Foto" (Refresh):** Jika pengguna salah memilih foto di halaman `CapturePage`, tersedia tombol khusus untuk menghapus foto dan memilih ulang.

## 4. Consistency and Standards (Konsistensi dan Standar)
Pengguna tidak perlu bertanya-tanya apakah kata, situasi, atau tindakan yang berbeda memiliki arti yang sama. Ikuti standar platform.

*   **Penerapan:**
    *   **Desain Material 3:** Aplikasi menggunakan pedoman bentuk, jarak, dan gaya komponen Material Design 3 (tombol membulat, kartu dengan *shadow* yang halus).
    *   **Warna Utama:** Skema warna utama (Primer/Aksen) digunakan konsisten pada bagian-bagian yang dapat diklik (tombol, ikon utama, step aktif).
    *   **Terminologi:** Kata "Gaya Rambut", "AI", "Masuk", dan "Daftar" digunakan konsisten di semua halaman. Tidak ada pencampuran dengan istilah lain seperti "Sign In" atau "Model".

## 5. Error Prevention (Pencegahan Kesalahan)
Desain yang baik mencegah terjadinya masalah sebelum muncul, lebih baik daripada pesan error yang bagus.

*   **Penerapan:**
    *   **Konfirmasi Keluar (Logout):** Menambahkan kotak dialog konfirmasi *"Keluar dari Akun?"* ketika pengguna menekan ikon pintu keluar. Ini mencegah klik tidak sengaja yang memaksa mereka login kembali.
    *   **Validasi *Real-time* Form:** Pada saat membuat akun, form langsung mengecek kekuatan password dan mencocokkan konfirmasi password sebelum tombol Daftar ditekan.

## 6. Recognition Rather Than Recall (Mengenali Lebih Baik Daripada Mengingat)
Minimalkan beban ingatan pengguna dengan membuat elemen, tindakan, dan opsi terlihat jelas.

*   **Penerapan:**
    *   **Tooltip Deskriptif:** Ikon riwayat dan keluar di beranda dilengkapi dengan atribut `tooltip`. Jika ditekan lama, akan muncul penjelasan teks fungsinya.
    *   **Visualisasi Katalog:** Gaya rambut di `CatalogPage` tidak hanya berupa daftar nama teks, tetapi dilengkapi gambar foto contoh dan deskripsi singkat (*"Belahan samping rapi, tampilan profesional..."*) agar pengguna tidak perlu mengingat nama ilmiah gaya rambut tersebut.

## 7. Flexibility and Efficiency of Use (Fleksibilitas dan Efisiensi Penggunaan)
Akselerator (jalan pintas) — yang tidak terlihat oleh pengguna pemula — sering kali dapat mempercepat interaksi bagi pengguna ahli.

*   **Penerapan:**
    *   **Metode Ambil Foto:** Pengguna diberikan dua tombol *shortcut* (jalan pintas) eksplisit: "Dari Galeri" dan "Kamera". Tidak ada menu tersembunyi.
    *   **Tombol "Simpan & Selesai":** Di halaman `ResultPage`, tombol ini menggunakan fungsi `popUntil` (jalan pintas) yang langsung melempar pengguna kembali ke halaman utama dalam 1 ketukan, alih-alih harus menekan *back* 3 kali.

## 8. Aesthetic and Minimalist Design (Estetika dan Desain Minimalis)
Antarmuka tidak boleh mengandung informasi yang tidak relevan atau jarang dibutuhkan.

*   **Penerapan:**
    *   **Empty State Visual:** Saat halaman Riwayat (`HistoryPage`) masih kosong, layar tidak dibiarkan hitam kosong. Terdapat ikon besar pudar dan tulisan "Belum ada riwayat" yang menjaga kerapian visual.
    *   **Layout *Clean*:** Tata letak dikelompokkan dengan jarak yang lega (*white space*). Tidak ada elemen bertumpuk. Status *bar* dibersihkan dan difokuskan pada kartu aksi di tengah.

## 9. Help Users Recognize, Diagnose, and Recover from Errors (Bantu Pengguna Mengenali, Mendiagnosis, dan Memperbaiki Kesalahan)
Pesan error harus dinyatakan dalam bahasa yang sederhana, secara tepat menunjukkan masalah, dan secara konstruktif menyarankan solusi.

*   **Penerapan:**
    *   **Error AI Spesifik:** Di halaman `CapturePage`, penanganan *error* telah diperinci:
        *   Jika *server mati/koneksi putus*: "Tidak dapat terhubung ke server AI. Pastikan server Colab aktif."
        *   Jika *server lama merespons*: "Server tidak merespons. Model AI mungkin sedang loading."
        *   Jika *foto terlalu HD/besar*: "Foto terlalu besar. Gunakan foto dengan ukuran lebih kecil."
    *   Semua *error* ini ditampilkan dalam bentuk **Snackbar merah (Floating)** yang sangat mudah dilihat.

## 10. Help and Documentation (Bantuan dan Dokumentasi)
Sebaiknya sistem tidak memerlukan penjelasan, tetapi bantuan dan dokumentasi mungkin diperlukan.

*   **Penerapan:**
    *   **Tips Kontekstual:** Di bawah kartu aksi pada `HomePage`, terdapat kotak bantuan dengan ikon lampu pijar (*"Tips: Untuk hasil terbaik..."*) yang memandu pengguna pemula.
    *   **Bantuan *Zoom* (Pinch):** Pada `ResultPage` (halaman hasil), terdapat stiker semi-transparan kecil berbunyi "Cubit untuk zoom", membantu pengguna memahami bahwa fitur *pan & zoom* tersedia untuk gambar hasil.
    *   **Instruksi Input Tepat:** Pada kolom foto yang kosong, ada teks pembantu: "Unggah selfie wajah menghadap ke depan untuk hasil AI terbaik."
