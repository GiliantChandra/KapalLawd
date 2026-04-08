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
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting image: $e')),
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

      // Connect to Python ML server (running locally on PC / Tunneling)
      final prefs = await SharedPreferences.getInstance();
      final String apiUrl = prefs.getString('api_url') ?? "http://192.168.100.140:8000/generate-hairstyle";
      
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.maxRedirects = 9999; // Toleransi ekstrim sistem Polling Cloud Modal (Bisa memakan 300+ detik)
      request.fields['user_id'] = user.uid;
      request.fields['style_name'] = widget.styleName;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Try ${widget.styleName}',
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
                  child: Image.asset(
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
                        'Target Style',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Text(
                        widget.styleName,
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
            
            const SizedBox(height: 48),
            
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
                          size: 80,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload a direct front-facing selfie\nfor the best AI results',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60),
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
                      label: const Text('Gallery'),
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
                      label: const Text('Camera'),
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
                  IconButton(
                    onPressed: () => setState(() => _imageFile = null),
                    icon: const Icon(Icons.refresh_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(16),
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
                      child: _isProcessing
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black87, 
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Generate Hairstyle',
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
