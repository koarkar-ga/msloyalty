import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/get_device_info.dart';
import 'package:msloyalty/Helpers/showSnackBar.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetPasswordPage extends StatefulWidget {
  final String phone;
  final String name;
  final String? email;
  final DateTime? dob;
  final File? imageFile;

  const SetPasswordPage({
    super.key,
    required this.phone,
    required this.name,
    required this.dob,
    required this.email,
    required this.imageFile,
  });

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final supabase = Supabase.instance.client;

  Future<void> _completeRegistration() async {
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      showSnackBar(context, "Please fill in all fields", isError: true);
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      showSnackBar(context, "Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRes = await supabase.auth.signUp(
        email: "${widget.phone}@moonsungroup.com",
        password: _passwordController.text.trim(),
      );

      final userId = authRes.user?.id;
      if (userId != null) {
        String? imageUrl;
        if (widget.imageFile != null) {
          final String filePath = 'public/profile_${widget.phone}.jpg';
          await supabase.storage.from('moonsun_assets').upload(filePath, widget.imageFile!);
          imageUrl = supabase.storage.from('moonsun_assets').getPublicUrl(filePath);
        }

        await supabase.from('profiles').insert({
          'id': userId,
          'full_name': widget.name,
          'phone_number': widget.phone,
          'avatar_url': imageUrl,
          'dob': widget.dob?.toIso8601String(),
          'email': widget.email,
          'member_id': "MS-${Random().nextInt(99999).toString().padLeft(5, '0')}",
          'total_points': 0, // Should probably start at 0 or a welcome bonus
        });

        if (mounted) {
          final device = await getThisDeviceId();
          await saveUserLocalData(
            userId,
            device['device_id'] ?? "",
            device['device_name'] ?? "",
            device['device_model'] ?? "",
            device['device_type'] ?? "",
          );
          Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient ───────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A192F), Color(0xFF132B4F)],
              ),
            ),
          ),

          // ── Glowing Orbs ──────────────────────────────────────────────────
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
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
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Security",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Set Password",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Create a secure password to protect your account.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Glass Form Panel ──────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildGlassTextField(
                                    controller: _passwordController,
                                    label: "PASSWORD",
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildGlassTextField(
                                    controller: _confirmController,
                                    label: "CONFIRM PASSWORD",
                                    icon: Icons.lock_clock_outlined,
                                    obscureText: _obscureConfirm,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  const SizedBox(height: 48),

                                  // ── Action Button ────────────────────────────────
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF1B4F72), Color(0xFF0A192F)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1B4F72).withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _completeRegistration,
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
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text(
                                                "COMPLETE SIGNUP",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
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
                      ],
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
    bool obscureText = false,
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
