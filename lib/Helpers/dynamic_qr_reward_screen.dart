import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:msloyalty/Services/noti_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DynamicQRRewardScreen extends StatefulWidget {
  const DynamicQRRewardScreen({super.key});

  @override
  State<DynamicQRRewardScreen> createState() => _DynamicQRRewardScreenState();
}

class _DynamicQRRewardScreenState extends State<DynamicQRRewardScreen> {
  final supabase = Supabase.instance.client;
  String _qrData = "";
  int _secondsRemaining = 30;
  Timer? _timer;
  NotificationService notService = NotificationService();
  User? user;
  @override
  void initState() {
    super.initState();

    user = supabase.auth.currentUser;
    notService.listenToPointUpdates(context, user!.id);
    _generateSecureQR();
    _startTimer();
  }

  void _generateSecureQR() {
    if (user == null) return;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    const String appSecret = "MS_ENERGY_SECRET_KEY_2024";

    final bytes = utf8.encode("${user!.id}_${timestamp}_$appSecret");
    final String hash = sha256.convert(bytes).toString();

    final Map<String, dynamic> secureData = {"uid": user!.id, "t": timestamp, "h": hash};

    if (mounted) {
      setState(() {
        _qrData = jsonEncode(secureData);
        _secondsRemaining = 30;
      });
      print(_qrData);
    }
  }

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Point Reward QR", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInstructionCard(),
              const SizedBox(height: 30),
              _buildQRContainer(),
              const SizedBox(height: 30),
              _buildTimerUI(),
              const SizedBox(height: 30),
              _buildInstructions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(15)),
      child: const Row(
        children: [
          Icon(Icons.security, color: Colors.blue),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              "QR Code ကို ဝန်ထမ်းအားပြသ၍ Point ရယူပါ။ ၃၀ စက္ကန့်တိုင်း အလိုအလျောက် ပြောင်းလဲပါမည်။",
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRContainer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, spreadRadius: 5),
        ],
      ),
      child: QrImageView(
        data: _qrData,
        version: QrVersions.auto,
        size: 260.0,
        // Logo ထည့်သွင်းခြင်း
        embeddedImage: const AssetImage('assets/images/moonsun_logo.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(50, 50), // Logo အရွယ်အစား
        ),
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF2D3436)),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Color(0xFF2D3436),
        ),
        // Logo ကြောင့် Scan ဖတ်မရခြင်းမှ ကာကွယ်ရန် Error Correction Level မြှင့်ခြင်း
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ),
    );
  }

  Widget _buildTimerUI() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 3,
              width: 200,
              child: LinearProgressIndicator(
                value: _secondsRemaining / 30,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _secondsRemaining < 10 ? Colors.red : Colors.blue,
                ),
              ),
            ),
            // Text(
            //   "$_secondsRemaining",
            //   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            // ),
          ],
        ),
        const SizedBox(height: 15),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _instructionItem(Icons.screenshot_outlined, "Screenshot အဟောင်းများ အသုံးပြု၍မရပါ။"),
          const SizedBox(height: 12),
          _instructionItem(
            Icons.phonelink_ring_outlined,
            "ဝန်ထမ်းအား ဤ Screen ကို တိုက်ရိုက်ပြသပါ။",
          ),
        ],
      ),
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
