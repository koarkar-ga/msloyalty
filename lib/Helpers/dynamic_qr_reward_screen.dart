import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DynamicQRRewardScreen extends StatefulWidget {
  final String? rewardTitle;
  const DynamicQRRewardScreen({super.key, this.rewardTitle});

  @override
  State<DynamicQRRewardScreen> createState() => _DynamicQRRewardScreenState();
}

class _DynamicQRRewardScreenState extends State<DynamicQRRewardScreen> {
  final supabase = Supabase.instance.client;
  String? _tokenId;
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tokenId = null;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not logged in.';
          _isLoading = false;
        });
        return;
      }

      final expiresAt = DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();

      final data = await supabase
          .from('qr_tokens')
          .insert({
            'user_id': user.id,
            'action_type': 'redeem',
            'expires_at': expiresAt,
            'is_used': false,
          })
          .select()
          .single();

      setState(() {
        _tokenId = data['id'].toString();
        _secondsRemaining = 300;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      debugPrint('Error generating reward QR token: $e');
      setState(() {
        _error = 'Failed to generate QR: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.rewardTitle ?? 'Claim Reward'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Generating QR Code...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                )
              : _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _generateToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              : _tokenId == null
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    // Security notice
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.security,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'QR Code ကို ဝန်ထမ်းအားပြသ၍ Reward ရယူပါ။',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.blue[200]
                                    : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'REDEEM|$_tokenId',
                        version: QrVersions.auto,
                        size: 240.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: Color(0xFF2D3436),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: Color(0xFF2D3436),
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _secondsRemaining < 60
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _secondsRemaining < 60
                              ? Colors.redAccent
                              : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: _secondsRemaining < 60
                                    ? Colors.redAccent
                                    : Colors.green,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formattedTime,
                                style: TextStyle(
                                  color: _secondsRemaining < 60
                                      ? Colors.redAccent
                                      : Colors.green,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _secondsRemaining / 300,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _secondsRemaining < 60
                                    ? Colors.redAccent
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_secondsRemaining == 0) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'QR Expired',
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _generateToken,
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Generate New QR'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    // Instructions
                    Row(
                      children: [
                        const Icon(
                          Icons.screenshot_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Screenshot အဟောင်းများ အသုံးပြု၍မရပါ။',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.phonelink_ring_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ဝန်ထမ်းအား ဤ Screen ကို တိုက်ရိုက်ပြသပါ။',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
