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
  bool isPhoneAuth = false;
  bool isOtpSent = false;
  String _verificationId = '';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneRegController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);
    String phoneNum = _phoneController.text.trim();
    if (!phoneNum.startsWith('+')) {
      if (phoneNum.startsWith('0')) {
        phoneNum = '+62${phoneNum.substring(1)}';
      } else {
        phoneNum = '+62$phoneNum';
      }
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNum,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verifikasi gagal: Nomor tidak valid')));
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            isOtpSent = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode OTP SMS meluncur! 🚀')));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _submitOtp() async {
    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Kode OTP Salah!')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAuth() async {
    setState(() => _isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Validasi Nomor HP 10-13 Angka
        final phoneText = _phoneRegController.text.trim();
        if (phoneText.length < 10 || phoneText.length > 13) {
          throw FirebaseAuthException(
            code: 'invalid-phone-number', 
            message: 'Nomor HP harus terdiri dari 10-13 angka.'
          );
        }

        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        await FirebaseFirestore.instance.collection('User').doc(userCredential.user!.uid).set({
          'Email': _emailController.text.trim(),
          'Phone': phoneText,
          'Nama': _nameController.text.trim(),
          'Password': _passwordController.text.trim(), // PERINGATAN! TIDAK AMAN UNTUK PRODUKSI
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Authentication error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  Icons.content_cut_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'StyleSense AI',
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin 
                    ? (isPhoneAuth ? (isOtpSent ? 'Masukkan OTP SMS' : 'Login kilat via SMS HP') : 'Welcome back, ready for a new look?')
                    : 'Create an account to find your style',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                
                // TAB SWITCHER HANYA MUNCUL SAAT LOGIN
                if (isLogin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('📧 Email'),
                        selected: !isPhoneAuth,
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        onSelected: (val) => setState(() { isPhoneAuth = false; isOtpSent = false; }),
                      ),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('📱 No. HP'),
                        selected: isPhoneAuth,
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        onSelected: (val) => setState(() => isPhoneAuth = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                if (isLogin && isPhoneAuth) ...[
                  // ---------------- PHONE LOGIN LAYOUT ---------------- //
                  if (!isOtpSent) ...[
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: 'Nomor HP (+62...)',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.phone_android),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.black87) 
                          : const Text('Kirim OTP SMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan 6 Digit OTP',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.message),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(letterSpacing: 4),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.black87) 
                          : const Text('Verifikasi OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isOtpSent = false),
                      child: Text('Ganti Nomor HP?', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    )
                  ],

                ] else ...[
                  // ---------------- EMAIL LOGIN ATAU EMAIL REGISTER LAYOUT ---------------- //
                  if (!isLogin) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Nama Lengkap',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneRegController,
                      decoration: InputDecoration(
                        hintText: 'Nomor HP (10 - 13 Angka)',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 54,
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
                        : Text(isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = !isLogin;
                    isPhoneAuth = false; // Reset phone auth mode saat ubah layar
                    isOtpSent = false;
                  }),
                  child: Text(
                    isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
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
