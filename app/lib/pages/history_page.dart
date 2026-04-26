import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 60, color: Colors.white30),
              const SizedBox(height: 16),
              // [IMK: Help Users Recognize Errors] — Pesan ramah, bukan teknis
              Text(
                'Silakan login terlebih dahulu\nuntuk melihat riwayat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Gaya Rambut',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // [IMK: Visibility of System Status] — Loading state yang jelas
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat riwayat Anda...',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          // [IMK: Help Users Recognize Errors] — Pesan error ramah, tidak teknis
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 60, color: Colors.white30),
                    const SizedBox(height: 16),
                    Text(
                      'Riwayat tidak dapat dimuat.',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan koneksi internet Anda aktif dan coba lagi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          // [IMK: Visibility] — Empty state yang informatif
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_cut_rounded,
                      size: 72, color: Colors.white24),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada riwayat gaya rambut.',
                    style: GoogleFonts.outfit(
                        fontSize: 18, color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coba gaya pertama Anda sekarang!',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              // [IMK: Visibility] — Jumlah riwayat
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${docs.length} percobaan tersimpan',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final imageUrl =
                        data['resultImageUrl'] as String?;
                    final styleName =
                        data['styleName'] ?? 'Gaya Tidak Diketahui';

                    // [IMK: Visibility] — Format tanggal yang manusiawi
                    final timestamp = data['createdAt'] as Timestamp?;
                    final dateLabel = timestamp != null
                        ? DateFormat('d MMM yyyy', 'id_ID')
                            .format(timestamp.toDate())
                        : 'Tanggal tidak tersedia';

                    return InkWell(
                      onTap: () => _onItemTap(context, imageUrl),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // Gambar hasil
                            Expanded(
                              flex: 5,
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                child: _buildImageWidget(
                                    context, imageUrl),
                              ),
                            ),

                            // Info nama gaya + tanggal
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    10, 8, 10, 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      styleName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    // [IMK: Visibility of System Status] — Tampilkan tanggal
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 11,
                                            color: Colors.white38),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            dateLabel,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white38),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl == 'lokal_saja') {
      return Container(
        color:
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android_rounded,
                color:
                    Theme.of(context).colorScheme.primary,
                size: 28),
            const SizedBox(height: 6),
            const Text(
              'Tersimpan\ndi Perangkat',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      );
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) =>
              const Icon(Icons.broken_image, color: Colors.white30));
    }
    return Image.file(File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) =>
            const Icon(Icons.broken_image, color: Colors.white30));
  }

  void _onItemTap(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl == 'lokal_saja') {
      // [IMK: Informative Feedback] — Pesan yang jelas & membantu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Foto ini tersimpan di galeri perangkat Anda.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D2D3E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      // Tampilkan gambar fullscreen dengan tombol tutup yang jelas
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.startsWith('http')
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : Image.file(File(imageUrl), fit: BoxFit.contain),
                ),
              ),
              // [IMK: User Control & Freedom] — Tombol tutup yang mudah ditemukan
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 24),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
