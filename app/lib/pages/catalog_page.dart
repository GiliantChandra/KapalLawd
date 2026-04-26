import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'capture_page.dart';

final List<Map<String, String>> hairstyles = [
  {
    'name': 'Bald',
    'image': 'assets/katalog/bald.jpg',
    'desc': 'Bersih & maskulin, cocok untuk wajah oval dan persegi',
  },
  {
    'name': 'Edgar Cut',
    'image': 'assets/katalog/edgar_cut.jpg',
    'desc': 'Garis lurus rapi di atas dahi, tampilan modern & berani',
  },
  {
    'name': 'French Crop',
    'image': 'assets/katalog/french_crop.jpg',
    'desc': 'Poni pendek ke depan, santai namun tetap stylish',
  },
  {
    'name': 'Low Fade',
    'image': 'assets/katalog/low_fade.jpg',
    'desc': 'Gradasi halus di bagian bawah, tampilan bersih & elegan',
  },
  {
    'name': 'Warrior Cut',
    'image': 'assets/katalog/warrior_cut.jpg',
    'desc': 'Tampilan tebal berkarakter, cocok untuk rahang kuat',
  },
  {
    'name': 'Mullet',
    'image': 'assets/katalog/mullet.jpg',
    'desc': 'Pendek di depan, panjang di belakang — gaya retro ikonik',
  },
  {
    'name': 'Side Part',
    'image': 'assets/katalog/side_part.jpg',
    'desc': 'Belahan samping rapi, tampilan profesional & klasik',
  },
  {
    'name': 'Taper Fade',
    'image': 'assets/katalog/taper_fade.jpg',
    'desc': 'Sisi memudar halus, serbaguna untuk berbagai acara',
  },
];

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Katalog Gaya Rambut',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // [IMK: Help & Documentation] — Petunjuk cara penggunaan
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ketuk salah satu gaya untuk mencobanya langsung di foto Anda',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // [IMK: Visibility] — Jumlah item
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${hairstyles.length} gaya tersedia',
                style: const TextStyle(fontSize: 13, color: Colors.white38),
              ),
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: hairstyles.length,
              itemBuilder: (context, index) {
                final style = hairstyles[index];
                return _buildCatalogItem(
                  context,
                  style['name']!,
                  style['image']!,
                  style['desc']!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogItem(
      BuildContext context, String name, String imagePath, String description) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CapturePage(
              styleName: name,
              catalogImagePath: imagePath,
            ),
          ),
        );
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
            // Gambar katalog
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.black12,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white30),
                      ),
                    ),
                  ),
                  // [IMK: Affordance] — Label "Coba" untuk menandakan item bisa diklik
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'Coba',
                            style:
                                TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // [IMK: Help & Documentation] — Tombol info untuk membaca teks penuh
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                content: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Tutup', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CapturePage(
                                            styleName: name,
                                            catalogImagePath: imagePath,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Coba Gaya Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Icon(Icons.info_outline_rounded, size: 16, color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // [IMK: Recognition over Recall] — Deskripsi singkat (terpotong tidak apa-apa karena ada tombol info)
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
