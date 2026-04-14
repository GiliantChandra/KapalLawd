import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My History',
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan saat memuat riwayat.\nPastikan Firebase Rules diatur ke true.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300]),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat potongan rambut.',
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.white60),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final imageUrl = data['resultImageUrl'] as String?;
              final styleName = data['styleName'] ?? 'Unknown Style';

              return InkWell(
                onTap: () {
                  if (imageUrl == 'lokal_saja') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto ini aman tersimpan di Galeri/Memori HP Anda, tidak dicadangkan ke Cloud.')),
                    );
                  } else {
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
                                child: (imageUrl ?? '').startsWith('http')
                                    ? Image.network(imageUrl ?? '', fit: BoxFit.contain)
                                    : Image.file(File(imageUrl ?? ''), fit: BoxFit.contain),
                              ),
                            ),
                            Positioned(
                              top: -10,
                              right: -10,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: (imageUrl != null && imageUrl != 'lokal_saja')
                              ? (imageUrl.startsWith('http') 
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.white30),
                                    )
                                  : Image.file(
                                      File(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image, color: Colors.white30),
                                    ))
                              : Container(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Local\nSaved',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 10, color: Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          styleName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
