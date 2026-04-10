import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  final _otpController = TextEditingController();
  bool _showOtpStep = false;
  bool _otpCodeSent = false;
  bool _isLoading = false;
  String? _verificationId; // For Firebase Phone Auth

  // Function to validate password strength
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null; // Valid
  }

  Future<bool> _verifyOtpWithFirebase(String smsCode) async {
    if (_verificationId == null) {
      _showSnack('Verifikasi belum dimulai. Silakan kirim ulang OTP.');
      return false;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        if (email.isNotEmpty && password.isNotEmpty) {
          final emailCredential = EmailAuthProvider.credential(email: email, password: password);
          await userCredential.user!.linkWithCredential(emailCredential);
        }
      }

      _showSnack('Akun berhasil diverifikasi dan terhubung.');
      return true;
    } on FirebaseAuthException catch (e) {
      _showSnack('Kode OTP salah atau gagal diverifikasi: ${e.message}');
      return false;
    } catch (e) {
      _showSnack('Terjadi kesalahan saat verifikasi OTP: $e');
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
      _showSnack('Masukkan nomor telepon yang valid dengan kode negara, misal +628123456789.');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpCodeSent = false;
    });

    final normalizedPhone = phone.startsWith('+') ? phone : '+62${phone.replaceFirst(RegExp(r'^0+'), '')}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) async {
          if (!mounted) return;
          _showSnack('Verifikasi otomatis berhasil.');
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          if (!mounted) return;
          debugPrint('Verification failed: ${error.code} - ${error.message}');
          _showSnack('Gagal mengirim OTP: ${error.message}');
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _showOtpStep = true;
            _otpCodeSent = true;
          });
          _showSnack('OTP terkirim. Periksa SMS Anda.');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showSnack('Gagal melakukan verifikasi telepon: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitAuth() async {
    // For login, always sign in anonymously without validation
    if (isLogin) {
      setState(() => _isLoading = true);
      final navigator = Navigator.of(context);

      try {
        await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(const Duration(seconds: 30));
        // Navigation will be handled by AuthGate StreamBuilder.
        // If this page was pushed (e.g. from drawer), pop it.
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage;
        switch (e.code) {
          case 'network-request-failed':
            errorMessage = 'Network error. Check your internet connection.';
            break;
          default:
            errorMessage = e.message ?? 'Authentication error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } on TimeoutException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timed out. Check your internet connection and try again.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Validate inputs for sign up
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),      
      );
      return;
    }
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must include country code and be 8 to 15 digits long')),
      );
      return;
    }
    if (!_showOtpStep) {
      if (_passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),        
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {      
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
      final passwordError = _validatePassword(_passwordController.text);      
      if (passwordError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordError)),
        );
        return;
      }

      await _sendPhoneOtp();
      return;
    }

    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code')),
      );
      return;
    }

    final verified = await _verifyOtpWithFirebase(_otpController.text.trim());
    if (!verified) {
      return;
    }

    final navigator = Navigator.of(context);
    if (mounted && navigator.canPop()) {
      navigator.pop();
    }
    return;
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
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Email, phone and password fields (only for sign up)
                if (!isLogin) ...[
                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password field
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Phone number field
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone number (+628123456789)',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.phone_android_outlined),     
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // OTP fields (only when OTP step is shown)
                if (_showOtpStep) ...[
                  Text(
                    'Masukkan kode OTP yang dikirim ke ${_phoneController.text.trim()}',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      hintText: 'OTP code (6 digits)',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.message_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendPhoneOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Kirim Ulang OTP', textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black87)
                      : Text(
                          isLogin ? 'Sign In' : _showOtpStep ? 'Confirm' : 'Sign Up',
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Toggle auth mode
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      _showOtpStep = false;
                      _otpCodeSent = false;
                      _otpController.clear();
                      if (isLogin) {
                        _phoneController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _emailController.clear();
                      }
                    });
                  },
                  child: Text(
                    isLogin 
                      ? "Don't have an account? Sign Up" 
                      : "Already have an account? Sign In",
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
