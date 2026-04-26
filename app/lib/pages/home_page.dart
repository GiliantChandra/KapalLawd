import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'catalog_page.dart';
import 'capture_page.dart';
import 'history_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // [IMK: User Control & Freedom] — Konfirmasi sebelum logout
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Anda akan keluar dari StyleSense AI.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // [IMK: Match Real World] — Sapa dengan nama, bukan kode teknis
    final displayName = user?.displayName ??
        user?.email?.split('@').first ?? 'Pengguna';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'StyleSense AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          // [IMK: Recognition over Recall] — Tooltip deskriptif
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Gaya Rambut',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar dari Akun',
            onPressed: () => _confirmLogout(context), // [IMK: Error Prevention]
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [IMK: Informative Feedback] — Sapaan personal yang jelas
            Text(
              'Halo,',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              displayName.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih gaya rambut baru Anda hari ini.',
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 32),

            // [IMK: Informative Feedback] — Label seksi yang jelas
            Text(
              'Apa yang ingin Anda lakukan?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            // Kartu 1 — Katalog
            _buildActionCard(
              context: context,
              title: 'Katalog Gaya Rambut',
              subtitle: 'Pilih dari 8+ gaya dan coba langsung di foto Anda',
              icon: Icons.auto_awesome_mosaic_rounded,
              badge: '8 gaya',           // [IMK: Visibility of System Status]
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CatalogPage()),
              ),
            ),

            const SizedBox(height: 16),

            // Kartu 2 — Rekomendasi AI
            _buildActionCard(
              context: context,
              title: 'Rekomendasi AI',
              subtitle: 'AI mendeteksi bentuk wajah dan memilihkan gaya terbaik untuk Anda',
              icon: Icons.psychology_rounded,
              badge: 'Otomatis',          // [IMK: Visibility of System Status]
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CapturePage(
                    styleName: "AI_RECOMMENDATION",
                    catalogImagePath: "assets/katalog/edgar_cut.jpg",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // [IMK: Help & Documentation] — Petunjuk singkat
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tips: Untuk hasil terbaik, gunakan foto wajah menghadap ke depan dengan pencahayaan yang cukup.',
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        // [IMK: Visibility] — Badge informatif
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}
