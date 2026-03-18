import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'capture_page.dart';

final List<Map<String, String>> hairstyles = [
  {'name': 'Buzz Cut', 'image': 'assets/katalog/buzz_cut.jpg'},
  {'name': 'Edgar Cut', 'image': 'assets/katalog/edgar_cut.jpg'},
  {'name': 'French Crop', 'image': 'assets/katalog/french_crop.jpg'},
  {'name': 'Low Fade', 'image': 'assets/katalog/low_fade.jpg'},
  {'name': 'Middle Part', 'image': 'assets/katalog/middle_part.jpg'},
  {'name': 'Mullet', 'image': 'assets/katalog/mullet.jpg'},
  {'name': 'Side Part', 'image': 'assets/katalog/side_part.jpg'},
  {'name': 'Taper Fade', 'image': 'assets/katalog/taper_fade.jpg'},
];

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Style Catalog',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // Tinggi gambar lebih panjang sedikit
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: hairstyles.length,
        itemBuilder: (context, index) {
          final style = hairstyles[index];
          return _buildCatalogItem(context, style['name']!, style['image']!);
        },
      ),
    );
  }

  Widget _buildCatalogItem(BuildContext context, String name, String imagePath) {
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.black12,
                    child: const Icon(Icons.broken_image, color: Colors.white30),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
