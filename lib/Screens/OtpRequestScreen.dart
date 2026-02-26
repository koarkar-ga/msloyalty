import 'dart:async';

import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  String phone;
  int? requestId;
  OtpScreen({super.key, required this.phone, required this.requestId});

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

  /// ဖုန်းနံပါတ်၏ နောက်ဆုံး ၄ လုံးကိုသာ ပြသပေးမယ့် Function
  String maskPhoneNumber(String phone) {
    // ဖုန်းနံပါတ် အရှည်ကို စစ်ဆေးသည်
    if (phone.length <= 4) return phone;

    // နောက်ဆုံး ၄ လုံးကို ယူသည်
    String lastFourDigits = phone.substring(phone.length - 4);

    // ကျန်တဲ့အပိုင်းကို '*' ဖြင့် အစားထိုးသည်
    String maskedPart = '*' * (phone.length - 4);

    return '$maskedPart$lastFourDigits';
  }

  void startTimer() {
    _start = 30;
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
      // Simulate API Call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verifying OTP: $otp'),
            backgroundColor: const Color(0xFF1B4F72),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String maskedPhone = maskPhoneNumber(widget.phone);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Verify Code",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4F72),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  text: "We have sent a 6-digit verification code to ",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: maskedPhone, //"09 **** 123",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // OTP Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),

              const SizedBox(height: 40),

              // Resend Timer
              Center(
                child: Column(
                  children: [
                    _start > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Resend code in ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                "00:${_start.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4F72),
                                ),
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: startTimer,
                            child: const Text(
                              "Resend New Code",
                              style: TextStyle(
                                color: Color(0xFF1B4F72),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _controllers.any((e) => e.text.isEmpty)
                      ? null
                      : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Verify OTP",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1B4F72), width: 2),
          ),
          fillColor: _controllers[index].text.isNotEmpty
              ? const Color(0xFFF0F7FF)
              : Colors.white,
          filled: true,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {}); // Update button state
        },
      ),
    );
  }
}
