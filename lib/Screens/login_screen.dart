import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Helpers/get_device_info.dart';
import 'package:msloyalty/Screens/signup_screen.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:msloyalty/Services/smspoh_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Services/activity_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isOtpSent = false;
  int? _lastRequestId;
  bool _isPasswordMode = true;
  bool _obscurePassword = true;
  bool _isForgotPasswordMode = false;
  int _forgotStep = 1; // 1: Phone, 2: OTP, 3: New Password
  final TextEditingController _newPasswordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSingleDeviceLogin();
  }

  Future<void> _checkSingleDeviceLogin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select('last_device_id')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return;

      Map<String, dynamic> currentId = await getThisDeviceId();

      if (data['last_device_id'] != currentId['device_id']) {
        await supabase.auth.signOut();
        if (mounted) {
          _showSecurityAlertDialog(context);
        }
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Security check error: $e");
    }
  }

  Future<void> _updateDeviceId(String userId) async {
    try {
      Map<String, dynamic> currentId = await getThisDeviceId();
      await supabase
          .from('profiles')
          .update({
            'last_device_id': currentId['device_id'],
            'last_login_at': DateTime.now().toIso8601String(),
            'device_type': currentId['device_type'],
            'device_name': currentId['device_name'],
            'device_model': currentId['device_model'],
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint("Error updating device ID: $e");
    }
  }

  void _loginWithPassword() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      final response = await supabase.auth.signInWithPassword(
        email: "$phone@moonsungroup.com",
        password: password,
      );

      if (response.user != null) {
        await _updateDeviceId(response.user!.id);

        final device = await getThisDeviceId();
        await saveUserLocalData(
          response.user!.id,
          device['device_id'] ?? "",
          device['device_name'] ?? "",
          device['device_model'] ?? "",
          device['device_type'] ?? "",
        );

        await ActivityService.logActivity(
          actionType: 'login',
          description: 'User logged in via Password',
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/app');
        }
      }
    } catch (e) {
      _showSnackBar("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _requestOtp() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar("Please enter your phone number");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();

      // Check if user exists
      final existingUser = await supabase
          .from('profiles')
          .select('id')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingUser == null) {
        _showSnackBar("User not found. Please sign up first.");
        return;
      }

      final response = await SMSPohService.requestOTP(phone);
      if (response != null) {
        setState(() {
          _isOtpSent = true;
          _lastRequestId = response['requestId'];
        });
        _showSnackBar("OTP sent successfully");
      } else {
        _showSnackBar("Failed to send OTP");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final otpCode = _otpController.text;
    if (otpCode.length < 6) {
      _showSnackBar("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    final verifyUrl =
        "https://v3.smspoh.com/api/otp/verify?accessToken=RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ&to=${_phoneController.text}&code=$otpCode&requestId=$_lastRequestId";

    try {
      final response = await http.post(Uri.parse(verifyUrl));
      if (response.statusCode == 200) {
        final userProfile = await supabase
            .from('profiles')
            .select('*')
            .eq('phone_number', _phoneController.text)
            .maybeSingle();

        if (userProfile != null) {
          await _updateDeviceId(userProfile['id']);

          final device = await getThisDeviceId();
          await saveUserLocalData(
            userProfile['id'],
            device['device_id'] ?? "",
            device['device_name'] ?? "",
            device['device_model'] ?? "",
            device['device_type'] ?? "",
          );

          await ActivityService.logActivity(
            actionType: 'login',
            description: 'User logged in via OTP Verification',
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/app');
          }
        }
      } else {
        _showSnackBar("Invalid OTP");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar("Please enter your phone number");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_forgotStep == 1) {
        // Step 1: Request OTP for password reset
        final userExists = await supabase
            .from('profiles')
            .select('id')
            .eq('phone_number', phone)
            .maybeSingle();

        if (userExists == null) {
          _showSnackBar("User not found with this phone number");
          return;
        }

        final response = await SMSPohService.requestOTP(phone);
        if (response != null) {
          setState(() {
            _forgotStep = 2;
            _lastRequestId = response['requestId'];
          });
          _showSnackBar("OTP sent for password reset");
        } else {
          _showSnackBar("Failed to send OTP");
        }
      } else if (_forgotStep == 2) {
        // Step 2: Verify OTP
        final otp = _otpController.text.trim();
        final success = await SMSPohService.verifyOTP(
          phoneNumber: phone,
          otp: otp,
          requestId: _lastRequestId,
        );

        if (success) {
          setState(() => _forgotStep = 3);
          _showSnackBar("OTP Verified. Please enter new password.");
        } else {
          _showSnackBar("Invalid OTP");
        }
      } else if (_forgotStep == 3) {
        // Step 3: Reset Password
        final newPass = _newPasswordController.text;
        if (newPass.length < 6) {
          _showSnackBar("Password must be at least 6 characters");
          return;
        }

        final result = await supabase.rpc('update_user_password', params: {
          'phone': phone,
          'new_password': newPass,
        });

        if (result['status'] == 'success') {
          _showSnackBar("Password updated successfully! Please login.");
          setState(() {
            _isForgotPasswordMode = false;
            _forgotStep = 1;
            _passwordController.text = newPass;
            _isPasswordMode = true;
          });
        } else {
          _showSnackBar("Error: ${result['message']}");
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSecurityAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.security_update_warning_rounded,
                color: Color(0xFFC62828),
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                "Security Alert!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Your account was logged in from another device. For security, you have been logged out of this device.",
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B4F72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Deep Space Background Gradient ────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A192F), Color(0xFF132B4F)],
              ),
            ),
          ),

          // ── Animated Orbs for Depth ──────────────────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B4F72).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Logo Section ──────────────────────────────────────────
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.network(
                          'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
                          height: 70,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.stars,
                            color: Color(0xFFFFD700),
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Glassmorphism Form Panel ──────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Sign in to continue to your rewards",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.vpn_lock_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "VPN ကို ပိတ်ပြီးမှ OTP ရယူပါရန် မေတ္တာရပ်ခံအပ်ပါသည်။",
                                        style: TextStyle(
                                          color: Colors.amber.shade200,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Auth Mode Switcher ───────────────────────────
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGlassTab(
                                        "Password",
                                        _isPasswordMode,
                                        () => setState(
                                          () => _isPasswordMode = true,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildGlassTab(
                                        "OTP",
                                        !_isPasswordMode,
                                        () => setState(
                                          () => _isPasswordMode = false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ── Phone Input ──────────────────────────────────
                              _buildGlassTextField(
                                controller: _phoneController,
                                label: "PHONE NUMBER",
                                icon: Icons.phone_iphone_rounded,
                                keyboardType: TextInputType.phone,
                                enabled: !_isOtpSent,
                              ),
                              const SizedBox(height: 16),

                              // ── Password / OTP Input ─────────────────────────
                              if (_isPasswordMode)
                                _buildGlassTextField(
                                  controller: _passwordController,
                                  label: "PASSWORD",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                )
                              else if (_isForgotPasswordMode)
                                Column(
                                  children: [
                                    if (_forgotStep >= 2)
                                      _buildGlassTextField(
                                        controller: _otpController,
                                        label: "ENTER OTP",
                                        icon: Icons.verified_user_outlined,
                                        keyboardType: TextInputType.number,
                                      ),
                                    if (_forgotStep == 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: _buildGlassTextField(
                                          controller: _newPasswordController,
                                          label: "NEW PASSWORD",
                                          icon: Icons.vpn_key_outlined,
                                          obscureText: _obscurePassword,
                                        ),
                                      ),
                                  ],
                                )
                              else if (_isOtpSent)
                                _buildGlassTextField(
                                  controller: _otpController,
                                  label: "ENTER OTP",
                                  icon: Icons.verified_user_outlined,
                                  keyboardType: TextInputType.number,
                                ),

                              const SizedBox(height: 32),

                              // ── Action Button ────────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1B4F72),
                                        Color(0xFF0A192F),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1B4F72,
                                        ).withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : (_isForgotPasswordMode
                                              ? _handleForgotPassword
                                              : (_isPasswordMode
                                                    ? _loginWithPassword
                                                    : (_isOtpSent
                                                          ? _verifyOtp
                                                          : _requestOtp))),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _isForgotPasswordMode
                                                ? (_forgotStep == 1
                                                      ? "SEND RESET OTP"
                                                      : (_forgotStep == 2
                                                            ? "VERIFY OTP"
                                                            : "RESET PASSWORD"))
                                                : (_isPasswordMode
                                                      ? "LOGIN"
                                                      : (_isOtpSent
                                                            ? "VERIFY OTP"
                                                            : "SEND OTP")),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              if (_isPasswordMode && !_isForgotPasswordMode)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => setState(() {
                                      _isForgotPasswordMode = true;
                                      _forgotStep = 1;
                                    }),
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),

                              if (_isForgotPasswordMode)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: TextButton(
                                      onPressed: () => setState(() {
                                        _isForgotPasswordMode = false;
                                        _forgotStep = 1;
                                      }),
                                      child: const Text(
                                        "Back to Login",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (!_isPasswordMode && _isOtpSent && !_isForgotPasswordMode)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: TextButton(
                                      onPressed: () =>
                                          setState(() => _isOtpSent = false),
                                      child: const Text(
                                        "Change phone number?",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Register Section ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          ),
                          child: const Text(
                            "SIGN UP",
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white30,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.normal,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }
}
