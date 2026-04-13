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
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;

  // Function to validate password strength
  String? _validatePassword(String password) {
    if (password.length < 6) return 'Password minimal 6 karakter';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Harus mengandung huruf besar (Kapital)';
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?]').hasMatch(password)) return 'Harus mengandung karakter spesial/simbol';
    return null; // Valid
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.center)));
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
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final phone = _phoneController.text.trim();
        final name = _nameController.text.trim();

        if (email.isEmpty || password.isEmpty || phone.isEmpty || name.isEmpty) {
          throw FirebaseAuthException(code: 'empty-fields', message: 'Harap lengkapi semua kolom.');
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          throw FirebaseAuthException(code: 'password-mismatch', message: 'Password tidak sama!');
        }
        final passwordError = _validatePassword(password);      
        if (passwordError != null) {
          throw FirebaseAuthException(code: 'weak-password', message: passwordError);
        }
        if (!RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
          throw FirebaseAuthException(code: 'invalid-phone', message: 'Nomor HP tidak valid.');
        }

        // 1. Daftarkan dan Buat Kunci UID di Sistem Google
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. Simpan Data Metadata (Nama, HP) ke Firestore Database
        await FirebaseFirestore.instance.collection('User').doc(userCredential.user!.uid).set({
          'Email': email,
          'Phone': phone,
          'Nama': name,
          'Password': password, // PERINGATAN: TIDAK STANDAR AMAN UNTUK PRODUCTION REAL
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Tembakkan Peluru TAUTAN VERIFIKASI ke alamat Email pengguna 
        await userCredential.user!.sendEmailVerification();
        
        // 4. Force Logout agar mereka tidak bisa nembus gerbang utama
        await FirebaseAuth.instance.signOut();

        _showSnack('🎉 PEMBUATAN AKUN SUKSES! Tautan aktivasi telah dikirim ke Email ($email). Harap buka kotak masuk Email/Spam Anda untuk mengaktifkannya!');
        
        // Pindah otomatis kembali ke tab Log In
        setState(() {
          isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack('Gagal: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error tak terduga: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                  TextFormField(
                    controller: _phoneController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      hintText: 'Nomor HP (+62...)',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.phone_android_outlined),     
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator: (val) => val == null || !RegExp(r'^\+?\d{8,15}$').hasMatch(val) ? 'Masukkan 8-15 digit nomor telepon yang valid' : null,
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
                          isLogin ? 'Sign In' : 'Daftar Sekarang',
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
                    isLogin ? "Belum punya akun? Sign Up" : "Sudah punya akun? Sign In",
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
