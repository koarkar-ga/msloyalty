import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Helpers/showSnackBar.dart';
import 'package:msloyalty/Screens/OtpRequestScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Services/smspoh_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> _checkPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    try {
      final existingUser = await supabase
          .from('profiles')
          .select('id')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingUser != null) {
        if (mounted) {
          showSnackBar(
            context,
            "This phone number is already registered.",
            isError: true,
          );
        }
      } else {
        final response = await SMSPohService.requestOTP(phone);
        if (response != null) {
          if (mounted) {
            showSnackBar(context, "OTP sent successfully");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  phone: phone,
                  requestId: response['requestId'],
                  data: {
                    'username': _nameController.text.trim(),
                    'email': _emailController.text.trim(),
                    'dob': _dobController.text.trim(),
                  },
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            showSnackBar(context, "Failed to send OTP", isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Color(0xFF0A192F),
              surface: Color(0xFF1B4F72),
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF0A192F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
            top: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B4F72).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Custom Glass Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ── Logo Section ────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Image.network(
                              Config.logoImage,
                              height: 50,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.person_add_rounded,
                                color: Color(0xFFFFD700),
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                          const SizedBox(height: 16),

                          // ── Glassmorphism Form Panel ────────────────────────
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
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildGlassTextField(
                                      controller: _nameController,
                                      label: "FULL NAME",
                                      icon: Icons.person_outline_rounded,
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                          ? "Required"
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassTextField(
                                      controller: _phoneController,
                                      label: "PHONE NUMBER",
                                      icon: Icons.phone_iphone_rounded,
                                      keyboardType: TextInputType.phone,
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                          ? "Required"
                                          : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassTextField(
                                      controller: _emailController,
                                      label: "EMAIL ADDRESS (OPTIONAL)",
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassTextField(
                                      controller: _dobController,
                                      label: "DATE OF BIRTH",
                                      icon: Icons.cake_outlined,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                          ? "Required"
                                          : null,
                                    ),
                                    const SizedBox(height: 32),

                                    // ── Action Button ──────────────────────────────
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                              : _checkPhoneNumber,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  "CONTINUE",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 2,
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
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white38, size: 22),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
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
