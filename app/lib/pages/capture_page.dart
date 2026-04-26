import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'result_page.dart';

class CapturePage extends StatefulWidget {
  final String styleName;
  final String catalogImagePath;

  const CapturePage({
    super.key,
    required this.styleName,
    required this.catalogImagePath,
  });

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        // [IMK: Help Users Recognize Errors] — Pesan ramah, bukan stack trace
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.orange, size: 18),
                SizedBox(width: 10),
                Text('Gagal membuka foto. Pastikan izin kamera/galeri sudah diberikan.'),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _generateHaircut() async {
    if (_imageFile == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Harap login terlebih dahulu.");

      // KITA PAKSA TEMBAK COLAB SECARA DINAMIS VIA FIREBASE!
      // Mengambil URL secara 'Over The Air' dari kontrol pusat Firebase Firestore.
      final configSnapshot = await FirebaseFirestore.instance.collection('config').doc('api').get();
      final String apiUrl = (configSnapshot.data()?['url'] ?? "https://forty-pets-vanish.loca.lt/generate-hairstyle").toString().trim();

      // [KEAMANAN] Ambil Firebase ID Token — JWT kriptografis yang unik per sesi,
      // kadaluarsa otomatis setiap 1 jam. JAUH lebih aman dari static API Key.
      final idToken = await user.getIdToken(true); // true = paksa refresh token terbaru

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.maxRedirects = 9999;
      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      request.headers['User-Agent'] = 'KapalLawd-Mobile';
      // Kirim token sebagai Bearer di Authorization header (standar industri OAuth2)
      request.headers['Authorization'] = 'Bearer $idToken';
      request.fields['style_name'] = widget.styleName;
      // user_id tidak perlu dikirim lagi — diambil dari token yang sudah terverifikasi
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception("Gagal terhubung ke AI Server. Error: ${response.body}");
      }
      
      // KEAJAIBAN BARU (MODAL CLOUD): Decode JSON berisi sandi Base64 dari server
      final responseData = jsonDecode(response.body);

      final String faceShape = responseData['face_shape'] ?? 'Unknown';
      final String appliedStyle = responseData['style_applied'] ?? widget.styleName;
      final String base64String = responseData['image_base64'] ?? '';
      
      // Dekombinasi (Decode) sandi Base64 menjadi file foto sungguhan di memori permanen HP
      final documentDirectory = await getApplicationDocumentsDirectory();
      final String safeLocalPath = '${documentDirectory.path}/ai_result_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resultFile = File(safeLocalPath);
      await resultFile.writeAsBytes(base64Decode(base64String));

      // Gunakan URL lokal ini sebagai jembatan Firebase
      String imageUrl = safeLocalPath;

      // 2. Simpan path lokal murni ke Firestore Firebase (Bypass Cloud Storage Google 100%)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'styleName': appliedStyle,
          'faceShape': faceShape,
          'resultImageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint("Error (Terlewati/Timeout) riwayat Firestore: $e");
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      
      // Navigate to Result Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            styleName: appliedStyle,
            faceShape: faceShape,
            originalImage: resultFile,
            imageUrl: imageUrl,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        // [IMK: Help Users Recognize Errors] — Pesan spesifik sesuai jenis error
        String pesanError = 'Terjadi kesalahan. Silakan coba lagi.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('socketexception') || errStr.contains('connection')) {
          pesanError = 'Tidak dapat terhubung ke server AI. Pastikan server Colab aktif.';
        } else if (errStr.contains('timeout')) {
          pesanError = 'Server tidak merespons. Model AI mungkin sedang loading (±5 menit).';
        } else if (errStr.contains('401') || errStr.contains('403')) {
          pesanError = 'Sesi login habis. Silakan keluar dan login kembali.';
        } else if (errStr.contains('413')) {
          pesanError = 'Foto terlalu besar. Gunakan foto dengan ukuran lebih kecil.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(pesanError, style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF2D2D3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // [IMK: Visibility of System Status] — Tampilkan posisi user dalam alur 3 langkah
  Widget _buildStepIndicator(BuildContext context) {
    final steps = ['Pilih Foto', 'Proses AI', 'Lihat Hasil'];
    final currentStep = _imageFile == null ? 0 : 1;
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentStep;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? accent : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? accent : Colors.white30,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [IMK: Aesthetic & Minimalist] — Rapikan nama tampilan tanpa mengubah data server
    final bool isAiMode = widget.styleName == 'AI_RECOMMENDATION';
    final String displayStyleName = isAiMode ? 'Rekomendasi AI Otomatis' : widget.styleName;

    return Scaffold(
      appBar: AppBar(
        // [IMK: Consistency] — Judul halaman dalam Bahasa Indonesia
        title: Text(
          'Coba $displayStyleName',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Target Style Mini Preview
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isAiMode 
                    ? Container(
                        height: 80,
                        width: 80,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        child: Icon(
                          Icons.psychology_rounded, 
                          size: 44, 
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Image.asset(
                        widget.catalogImagePath,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAiMode ? 'Mode Cerdas' : 'Target Style',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Text(
                        displayStyleName,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // [IMK: Visibility of System Status] — Step indicator proses
            _buildStepIndicator(context),

            const SizedBox(height: 24),
            // Photo Area
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _imageFile == null 
                    ? Colors.white10 
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 72,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        // [IMK: Consistency] — Teks dalam Bahasa Indonesia
                        Text(
                          'Unggah selfie wajah menghadap ke depan\nuntuk hasil AI terbaik',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan wajah terlihat jelas dan pencahayaan cukup',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            if (_imageFile == null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      // [IMK: Consistency] — Label Bahasa Indonesia
                      label: const Text('Dari Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Kamera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Action when image is selected
              Row(
                children: [
                  // [IMK: User Control] — Tombol ganti foto dengan tooltip jelas
                  Tooltip(
                    message: 'Ganti foto',
                    child: IconButton(
                      onPressed: () => setState(() => _imageFile = null),
                      icon: const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _generateHaircut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      // [IMK: Informative Feedback] — Teks berubah saat loading
                      child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black87,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('AI sedang memproses...'),
                            ],
                          )
                        : Text(
                            'Terapkan Gaya Rambut',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
