import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/set_password.dart';
import 'package:msloyalty/Services/smspoh_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final int? requestId;
  final Map<String, dynamic>? data;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.requestId,
    this.data,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _start = 30;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  String maskPhoneNumber(String phone) {
    if (phone.length <= 4) return phone;
    String lastFourDigits = phone.substring(phone.length - 4);
    String maskedPart = '*' * (phone.length - 4);
    return '$maskedPart$lastFourDigits';
  }

  void startTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length == 6) {
      setState(() => _isLoading = true);
      
      Widget nextPage = Container();
      if (widget.data != null) {
        nextPage = SetPasswordPage(
          phone: widget.phone,
          name: widget.data!['username'] ?? widget.data!['name'] ?? '',
          dob: widget.data!['dob'] != null ? DateTime.tryParse(widget.data!['dob']) : null,
          email: widget.data!['email'],
          imageFile: null,
        );
      }

      SMSPohService.verifyAndNext(
        context,
        otp,
        widget.phone,
        widget.requestId,
        nextPage,
      ).whenComplete(() {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String maskedPhone = maskPhoneNumber(widget.phone);
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
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.06),
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
                        "Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
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
                          "Verify Code",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            text: "We have sent a 6-digit verification code to ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 15,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: maskedPhone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Glass OTP Fields ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) => _buildOtpBox(index)),
                        ),

                        const SizedBox(height: 48),

                        // ── Resend Timer ──────────────────────────────────────────
                        Center(
                          child: _start > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer_outlined, color: Colors.white38, size: 16),
                                      const SizedBox(width: 8),
                                      const Text("Resend code in ", style: TextStyle(color: Colors.white38)),
                                      Text(
                                        "00:${_start.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFFFD700),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton(
                                  onPressed: startTimer,
                                  child: const Text(
                                    "Resend New Code",
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 80),

                        // ── Verify Button ─────────────────────────────────────────
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
                              onPressed: _controllers.any((e) => e.text.isEmpty) || _isLoading
                                  ? null
                                  : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      "VERIFY OTP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 60,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focusNodes[index].hasFocus 
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: 1.2,
              ),
            ),
            child: Center(
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                decoration: const InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                  }
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
