import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'StyleSense AI',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email?.split('@').first.toUpperCase() ?? 'USER',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),
            
            // Mode 1 Card (Catalog)
            _buildActionCard(
              context: context,
              title: 'Hairstyle Catalog',
              subtitle: 'Pick a hairstyle and try it on instantly',
              icon: Icons.auto_awesome_mosaic_rounded,
              onTap: () {
                // TODO: Navigate to Catalog Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catalog Feature Coming Soon!')),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Mode 2 Card (AI Recommendation)
            _buildActionCard(
              context: context,
              title: 'AI Recommendation',
              subtitle: 'Let AI analyze your face and suggest styles',
              icon: Icons.psychology_rounded,
              onTap: () {
                // TODO: Navigate to AI Guide Page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Recommendation Coming Soon!')),
                );
              },
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white10,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }
}
