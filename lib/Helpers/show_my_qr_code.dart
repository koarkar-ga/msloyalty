import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  final supabase = Supabase.instance.client;
  String _qrData = "";
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateSecureQR();
    _startTimer();
  }

  // QR Code ထုတ်လုပ်သည့် Logic
  void _generateSecureQR() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // အချိန်အလိုက် ပြောင်းလဲနေမည့် Token ထုတ်ခြင်း
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    // လုံခြုံရေးအတွက် Secret Key တစ်ခုသတ်မှတ်ပါ (Admin/Backend ဘက်မှာလည်း ဒါကိုပဲသုံးရမည်)
    const String appSecret = "MS_ENERGY_SECRET_KEY_2025";

    // User ID + Timestamp + Secret ကိုပေါင်းပြီး SHA256 Hash လုပ်ပါသည်
    final bytes = utf8.encode("${user.id}_${timestamp}_$appSecret");
    final String hash = sha256.convert(bytes).toString();

    // QR ထဲမှာ သိမ်းမည့် Data (JSON format)
    final Map<String, dynamic> secureData = {
      "uid": user.id, // User ID
      "t": timestamp, // Generated Time
      "h": hash, // Verification Hash
      "v": "1.0", // Version
    };

    if (mounted) {
      setState(() {
        _qrData = jsonEncode(secureData);
        _secondsRemaining = 30; // စက္ကန့် ၃၀ ပြန်စမည်
      });
    }
  }

  // အချိန်မှတ်နာရီ (Countdown Timer)
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        // သုညရောက်သွားလျှင် QR အသစ်ပြန်ထုတ်မည်
        _generateSecureQR();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Point ရယူရန် QR", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // လုံခြုံရေး သတိပေးချက်
              _buildSecurityBanner(),
              const SizedBox(height: 40),

              // QR Code ပြသသည့် ဧရိယာ
              Center(
                child: Column(
                  children: [_buildQRFrame(), const SizedBox(height: 30), _buildTimerIndicator()],
                ),
              ),

              const SizedBox(height: 50),
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "ဤ QR Code သည် စက္ကန့် ၃၀ ပြည့်တိုင်း အလိုအလျောက် ပြောင်းလဲနေပါမည်။",
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRFrame() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _secondsRemaining < 10 ? Colors.red.shade300 : Colors.blue.shade100,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: _qrData,
        version: QrVersions.auto,
        size: 240.0,
        // Logo ထည့်သွင်းခြင်း
        embeddedImage: const AssetImage('assets/images/moonsun_logo.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(50, 50), // Logo အရွယ်အစား
        ),
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A1A)),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildTimerIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: _secondsRemaining / 30,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsRemaining < 10 ? Colors.red : Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "သက်တမ်းကုန်ရန်: $_secondsRemaining စက္ကန့်",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: _secondsRemaining < 10 ? Colors.red : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        _instructionItem(Icons.screenshot_outlined, "Screenshot အဟောင်းများ အသုံးပြု၍မရပါ။"),
        const SizedBox(height: 12),
        _instructionItem(Icons.phonelink_ring_outlined, "ဝန်ထမ်းအား ဤ Screen ကို တိုက်ရိုက်ပြသပါ။"),
      ],
    );
  }

  Widget _instructionItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }
}
