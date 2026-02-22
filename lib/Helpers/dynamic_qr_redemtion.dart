import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// QR ပြသရန်အတွက် (pubspec.yaml မှာ qr_flutter: ^4.1.0 ထည့်ထားဖို့လိုပါတယ်)
// import 'package:qr_flutter/qr_flutter.dart';

class DynamicQRRedemption extends StatefulWidget {
  final Map<String, dynamic> item;

  const DynamicQRRedemption({super.key, required this.item});

  @override
  State<DynamicQRRedemption> createState() => _DynamicQRRedemptionState();
}

class _DynamicQRRedemptionState extends State<DynamicQRRedemption> {
  final supabase = Supabase.instance.client;
  late Timer _timer;
  int _secondsRemaining = 30;
  late String _qrData;

  @override
  void initState() {
    super.initState();
    _generateNewQR();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ၃၀ စက္ကန့်တစ်ကြိမ် QR data အသစ်ထုတ်ပေးခြင်း
  void _generateNewQR() {
    final userId = supabase.auth.currentUser?.id ?? "unknown";
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      // Timestamp ထည့်ခြင်းဖြင့် QR ကို ၃၀ စက္ကန့်တစ်ကြိမ် Data ပြောင်းစေသည်
      _qrData = "REWARD:${widget.item['id']}|USER:$userId|TS:$timestamp";
      _secondsRemaining = 30;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        _generateNewQR();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _processRedemption() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Supabase RPC ခေါ်ယူခြင်း
      await supabase.rpc(
        'process_reward_redemption',
        params: {
          'target_user_id': userId,
          'target_reward_id': widget.item['id'],
          'required_points': widget.item['points_required'],
        },
      );

      if (!mounted) return;
      _showFeedback(true, "လဲလှယ်မှု အောင်မြင်ပါသည်။");
    } catch (e) {
      _showFeedback(false, "အမှားအယွင်းရှိပါသည်: ${e.toString()}");
    }
  }

  void _showFeedback(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(success ? "Success" : "Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (success) Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("လဲလှယ်မှု အတည်ပြုရန်"),
        backgroundColor: const Color(0xFF1B4F72),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.item['title'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "${widget.item['points_required']} Points နှုတ်ယူပါမည်",
                style: const TextStyle(color: Colors.orange, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // QR Code Section
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1B4F72), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: const Icon(Icons.qr_code_2, size: 200, color: Color(0xFF1B4F72)),
                      // အမှန်တကယ်သုံးလျှင်: QrImageView(data: _qrData, size: 250),
                    ),
                  ),
                  // စက္ကန့်ပြည့်လျှင် ပျောက်သွားမည့် Loading Overlay (Optional)
                  if (_secondsRemaining < 2)
                    Container(
                      width: 250,
                      height: 250,
                      color: Colors.white.withOpacity(0.8),
                      child: const CircularProgressIndicator(),
                    ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    "QR သက်တမ်းကုန်ရန်: $_secondsRemaining စက္ကန့်",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _processRedemption,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "လဲလှယ်မှုကို အတည်ပြုပါ",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("မလုပ်တော့ပါ", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
