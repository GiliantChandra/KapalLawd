import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AuthPageWhatsApp extends StatefulWidget {
  const AuthPageWhatsApp({super.key});

  @override
  State<AuthPageWhatsApp> createState() => _AuthPageWhatsAppState();
}

class _AuthPageWhatsAppState extends State<AuthPageWhatsApp> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtpStep = false;
  bool _otpCodeSent = false;
  bool _isLoading = false;
  int _remainingTime = 0;
  Timer? _countdownTimer;
  String _otpMethod = 'whatsapp'; // 'whatsapp' atau 'sms'

  // Backend URL - ubah sesuai deployment Anda
  final String _backendUrl = 'https://your-backend-url.com'; // TODO: Update URL

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Password harus minimal 6 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 huruf besar';
    }
    if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?]').hasMatch(password)) {
      return 'Password harus mengandung minimal 1 karakter khusus';
    }
    return null;
  }

  /// Normalisasi nomor telepon ke format internasional (+62...)
  /// agar konsisten antara send-otp dan verify-otp
  String _normalizePhone(String phone) {
    // Hapus semua karakter selain digit dan +
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('0')) return '+62${phone.substring(1)}';
    if (phone.startsWith('62')) return '+$phone';
    return '+62$phone';
  }

  Future<void> _sendOtpWhatsApp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
      _showSnack('Masukkan nomor telepon yang valid, misal +628123456789 atau 08123456789.');
      return;
    }

    // Normalisasi di sisi Flutter agar sama dengan yang disimpan backend
    final phone = _normalizePhone(rawPhone);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/send-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phone,
          'method': _otpMethod, // 'whatsapp' atau 'sms'
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _showOtpStep = true;
          _otpCodeSent = true;
          _remainingTime = data['remaining_time'] ?? 300; // 5 menit default
        });

        _startCountdown();
        _showSnack(data['message'] ?? 'OTP berhasil dikirim');
      } else {
        final data = jsonDecode(response.body);
        _showSnack(data['detail'] ?? 'Gagal mengirim OTP');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _verifyOtp(String otpCode) async {
    // Normalisasi agar key cocok dengan yang disimpan saat send-otp
    final phone = _normalizePhone(_phoneController.text.trim());
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phone,
          'otp_code': otpCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['verified'] == true) {
          _showSnack('OTP berhasil diverifikasi!');
          _countdownTimer?.cancel();
          return true;
        } else {
          _showSnack(data['message'] ?? 'OTP tidak valid');
          return false;
        }
      } else {
        final data = jsonDecode(response.body);
        _showSnack(data['detail'] ?? 'Gagal verifikasi OTP');
        return false;
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    // Normalisasi agar konsisten dengan OTP yang tersimpan
    final phone = _normalizePhone(_phoneController.text.trim());

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phone,
          'method': _otpMethod,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _remainingTime = data['remaining_time'] ?? 300;
          _otpController.clear();
        });

        _startCountdown();
        _showSnack(data['message'] ?? 'OTP berhasil dikirim ulang');
      } else {
        final data = jsonDecode(response.body);
        _showSnack(data['detail'] ?? 'Gagal mengirim ulang OTP');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (mounted) {
          setState(() {
            if (_remainingTime > 0) {
              _remainingTime--;
            } else {
              timer.cancel();
            }
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitAuth() async {
    // Login
    if (isLogin) {
      setState(() => _isLoading = true);
      final navigator = Navigator.of(context);

      try {
        await FirebaseAuth.instance
            .signInAnonymously()
            .timeout(const Duration(seconds: 30));
        
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication error')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Sign Up - Validate inputs
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Masukkan email Anda');
      return;
    }

    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
      _showSnack('Masukkan nomor telepon yang valid');
      return;
    }

    if (!_showOtpStep) {
      if (_passwordController.text.trim().isEmpty) {
        _showSnack('Masukkan password Anda');
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnack('Password tidak sesuai');
        return;
      }

      final passwordError = _validatePassword(_passwordController.text);
      if (passwordError != null) {
        _showSnack(passwordError);
        return;
      }

      await _sendOtpWhatsApp();
      return;
    }

    // Verify OTP
    if (_otpController.text.trim().isEmpty) {
      _showSnack('Masukkan kode OTP');
      return;
    }

    if (_otpController.text.trim().length != 6) {
      _showSnack('OTP harus 6 digit');
      return;
    }

    final verified = await _verifyOtp(_otpController.text.trim());
    if (!verified) {
      return;
    }

    // TODO: Create user account with Firebase or your backend
    // After verification, navigate or proceed to next step
    final navigator = Navigator.of(context);
    if (mounted && navigator.canPop()) {
      navigator.pop();
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
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // Sign up fields
                if (!isLogin) ...[
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
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone (+628123456789)',
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

                  // OTP method selection
                  if (!_showOtpStep)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih cara menerima OTP:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SegmentedButton<String>(
                                segments: const <ButtonSegment<String>>[
                                  ButtonSegment<String>(
                                    value: 'whatsapp',
                                    label: Text('WhatsApp'),
                                    icon: Icon(Icons.chat),
                                  ),
                                  ButtonSegment<String>(
                                    value: 'sms',
                                    label: Text('SMS'),
                                    icon: Icon(Icons.message),
                                  ),
                                ],
                                selected: <String>{_otpMethod},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _otpMethod = newSelection.first;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                ],

                // OTP fields
                if (_showOtpStep) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Kode OTP dikirim ke ${_phoneController.text.trim()}',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sisa waktu: ${_formatTime(_remainingTime)}',
                          style: TextStyle(
                            color: _remainingTime < 60 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan 6 digit OTP',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.message_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
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
                          onPressed: (_isLoading || _remainingTime == 0) ? null : _resendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Kirim Ulang OTP'),
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
                            isLogin
                                ? 'Sign In'
                                : _showOtpStep
                                    ? 'Confirm'
                                    : 'Sign Up',
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
                    _countdownTimer?.cancel();
                  },
                  child: Text(
                    isLogin
                        ? "Belum punya akun? Daftar"
                        : "Sudah punya akun? Masuk",
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