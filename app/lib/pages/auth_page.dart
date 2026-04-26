import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;

  // Function to validate password strength
  String? _validatePassword(String password) {
    if (password.length < 6) return 'Password minimal 6 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Harus mengandung huruf besar (Kapital)';
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?]').hasMatch(password)) return 'Harus mengandung karakter spesial/simbol';
    return null; // Valid
  }

  // [IMK: Help Users Recognize Errors] — Terjemahkan semua kode error Firebase
  // ke pesan yang mudah dipahami pengguna awam
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      // ── Error Login ──────────────────────────────────────────
      case 'wrong-password':
        return 'Password yang Anda masukkan salah. Silakan coba lagi.';
      case 'user-not-found':
        return 'Email ini belum terdaftar. Silakan daftar terlebih dahulu.';
      case 'invalid-credential':
      case 'invalid-email':
        return 'Email atau password salah. Periksa kembali dan coba lagi.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi dukungan untuk bantuan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Tunggu beberapa menit lalu coba lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.';
      // ── Error Pendaftaran ─────────────────────────────────────
      case 'email-already-in-use':
        return 'Email ini sudah digunakan akun lain. Coba login atau gunakan email berbeda.';
      case 'operation-not-allowed':
        return 'Pendaftaran dengan email tidak diizinkan saat ini.';
      case 'weak-password':
        return e.message ?? 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      // ── Error Kustom ──────────────────────────────────────────
      case 'email-not-verified':
        return 'Email belum diverifikasi. Cek kotak masuk atau folder Spam Anda lalu klik tautan aktivasi.';
      case 'empty-fields':
      case 'password-mismatch':
        return e.message ?? 'Harap lengkapi semua kolom dengan benar.';
      // ── Fallback ──────────────────────────────────────────────
      default:
        return 'Terjadi kesalahan. Silakan coba lagi. (${e.code})';
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? Colors.red[300] : Colors.green[300],
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 5 : 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitAuth() async {
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // ========================== MODE LOGIN ==========================
        if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
          throw FirebaseAuthException(code: 'empty-fields', message: 'Harap isi Email dan Password Anda.');
        }

        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Validasi Anti-Bypass: Pengguna dilarang masuk jika TAUTAN EMAIL belum di klik
        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut(); // Tendang keluar sementara
          throw FirebaseAuthException(
            code: 'email-not-verified', 
            message: 'Akses Ditolak! Harap buka Gmail/Inbox Anda dan klik Tautan Verifikasi terlebih dahulu.'
          );
        }

      } else {
        // ========================== MODE SIGN UP (DAFTAR) ==========================
        final email    = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final name     = _nameController.text.trim();

        if (email.isEmpty || password.isEmpty || name.isEmpty) {
          throw FirebaseAuthException(code: 'empty-fields', message: 'Harap lengkapi semua kolom.');
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          throw FirebaseAuthException(code: 'password-mismatch', message: 'Password tidak sama!');
        }
        final passwordError = _validatePassword(password);      
        if (passwordError != null) {
          throw FirebaseAuthException(code: 'weak-password', message: passwordError);
        }

        // 1. Daftarkan dan Buat Kunci UID di Sistem Google
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update display name di profil Firebase Auth
        await userCredential.user!.updateDisplayName(name);

        // 2. Simpan Data Metadata (Nama, HP) ke Firestore Database
        await FirebaseFirestore.instance.collection('User').doc(userCredential.user!.uid).set({
          'Email': email,
          'Nama': name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Tembakkan Peluru TAUTAN VERIFIKASI ke alamat Email pengguna 
        await userCredential.user!.sendEmailVerification();
        
        // 4. Force Logout agar mereka tidak bisa nembus gerbang utama
        await FirebaseAuth.instance.signOut();

        _showSnack(
          '✅ Akun berhasil dibuat! Tautan aktivasi dikirim ke $email. Cek kotak masuk atau folder Spam Anda.',
          isError: false,
        );
        setState(() {
          isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // [IMK: Help Users Recognize Errors] — Tampilkan pesan yang dapat dipahami
      _showSnack(_getErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      // [IMK: Error Recovery] — Pesan generik, tidak ekspos detail teknis
      _showSnack('Terjadi kesalahan tak terduga. Pastikan koneksi internet Anda aktif dan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'StyleSense AI',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Masuk dan jelajahi gaya AI Anda.' : 'Pendaftaran dengan Verifikasi Gmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 48),
                
                // Fields Mode Sign Up Saja
                if (!isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Fields Mode Ganda (Login & Sign Up)
                TextFormField(
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Alamat Email',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                    if (!val.contains('@') || !val.contains('.')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password wajib diisi';
                    if (!isLogin) return _validatePassword(val);
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password (Sign Up Saja)
                if (!isLogin) ...[
                  TextFormField(
                    controller: _confirmPasswordController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Ulangi Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.password_rounded),
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (val != _passwordController.text) return 'Password tidak cocok!';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                // Tombol Puncak Aksi
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black87)
                      : Text(
                          // [IMK: Consistency] — Label tombol dalam Bahasa Indonesia
                          isLogin ? 'Masuk' : 'Daftar Sekarang',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Opsi Penukar Layar
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      if (isLogin) {
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  child: Text(
                    // [IMK: Consistency] — Konsisten dalam Bahasa Indonesia
                    isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
