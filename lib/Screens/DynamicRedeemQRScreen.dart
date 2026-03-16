import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:msloyalty/Services/activity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DynamicRedeemQRScreen extends StatefulWidget {
  final int rewardId;
  final String rewardTitle;
  const DynamicRedeemQRScreen({
    super.key,
    required this.rewardId,
    required this.rewardTitle,
  });

  @override
  State<DynamicRedeemQRScreen> createState() => _DynamicRedeemQRScreenState();
}

class _DynamicRedeemQRScreenState extends State<DynamicRedeemQRScreen> {
  final supabase = Supabase.instance.client;
  String? _tokenId;
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  RealtimeChannel? _subscription;
  bool _isUsed = false;

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final expiresAt = DateTime.now()
          .add(const Duration(minutes: 5))
          .toIso8601String();

      final data = await supabase
          .from('qr_tokens')
          .insert({
            'user_id': user.id,
            'action_type': 'redeem',
            'reward_id': widget.rewardId,
            'expires_at': expiresAt,
          })
          .select()
          .single();

      setState(() {
        _tokenId = data['id'];
        _secondsRemaining = 300;
      });

      await ActivityService.logActivity(
        actionType: 'GENERATE_QR',
        description: 'Customer requested a REDEEM QR Token for: ${widget.rewardTitle}',
        metadata: {
          'token_id': _tokenId,
          'reward_id': widget.rewardId,
          'reward_title': widget.rewardTitle,
        },
      );

      _startTimer();
      _listenToTokenUsage(data['id']);
    } catch (e) {
      debugPrint("Error generating QR token: $e");
    }
  }

  void _listenToTokenUsage(dynamic id) {
    final String tokenId = id.toString();
    _subscription = supabase
        .channel('qr_token_$tokenId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'qr_tokens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tokenId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData['is_used'] == true) {
              if (mounted) {
                // Log Reward Redemption Activity
                ActivityService.logActivity(
                  actionType: 'redeem_reward',
                  description: 'Reward redemption successful: ${widget.rewardTitle}',
                  metadata: {
                    'token_id': tokenId,
                    'reward_id': widget.rewardId,
                    'reward_title': widget.rewardTitle,
                  },
                );
                setState(() {
                  _isUsed = true;
                  _timer?.cancel();
                });
                // REMOVED Navigator.pop(context) to show success state
              }
            }
          },
        )
        .subscribe();
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
    _subscription?.unsubscribe();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Redeem Reward QR"), centerTitle: true),
      body: Center(
        child: _isUsed
            ? _buildSuccessView()
            : _tokenId == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.rewardTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: 'REDEEM|$_tokenId',
                          version: QrVersions.auto,
                          size: 250.0,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Show this QR to the station staff\nto claim your reward.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Valid for: $_formattedTime",
                        style: TextStyle(
                          color: _secondsRemaining < 60
                              ? Colors.redAccent
                              : Colors.green,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_secondsRemaining == 0)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _tokenId = null;
                            });
                            _generateToken();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Generate New QR"),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 100,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'SUCCESS!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.rewardTitle} ရရှိပြီး ဖြစ်ပါပြီ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "ကျေးဇူးတင်ပါသည်",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16, 
            color: isDark ? Colors.white70 : Colors.black54
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'ပိတ်မည်',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



