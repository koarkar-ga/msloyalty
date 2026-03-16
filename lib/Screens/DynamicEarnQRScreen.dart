import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:msloyalty/Services/activity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:msloyalty/Screens/FuelTransactionDetailScreen.dart';

class DynamicEarnQRScreen extends StatefulWidget {
  const DynamicEarnQRScreen({super.key});

  @override
  State<DynamicEarnQRScreen> createState() => _DynamicEarnQRScreenState();
}

class _DynamicEarnQRScreenState extends State<DynamicEarnQRScreen> {
  final supabase = Supabase.instance.client;
  String? _tokenId;
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isLoading = false;
  String? _errorMessage; // Renamed from _error to _errorMessage
  RealtimeChannel? _subscription;
  bool _isUsed = false;
  String? _earnedPoints; // Added _earnedPoints

  @override
  void initState() {
    super.initState();
    _generateToken();
  }

  Future<void> _generateToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Use _errorMessage
      _tokenId = null;
      _isUsed = false; // Reset _isUsed when generating a new token
      _earnedPoints = null; // Reset _earnedPoints
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in.'; // Use _errorMessage
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
            'action_type': 'earn',
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

      await ActivityService.logActivity(
        actionType: 'GENERATE_QR',
        description: 'Customer requested an EARN QR Token.',
        metadata: {'token_id': _tokenId},
      );

      _startTimer();
      _listenToTokenUsage(data['id']);
    } catch (e) {
      debugPrint('Error generating QR token: $e');
      setState(() {
        _errorMessage =
            'Failed to generate QR: ${e.toString()}'; // Use _errorMessage
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

  void _listenToTokenUsage(dynamic id) {
    final String tokenId = id.toString();
    _subscription = supabase
        .channel('qr_token_$tokenId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update, // Listen specifically for updates
          schema: 'public',
          table: 'qr_tokens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tokenId,
          ),
          callback: (payload) async {
            final newData = payload.newRecord;
            print(
              "DEBUG Realtime: Received update for token $tokenId. is_used: ${newData['is_used']}",
            );
            if (newData['is_used'] == true) {
              if (mounted) {
                // Log Point Collection Activity
                ActivityService.logActivity(
                  actionType: 'collect_point',
                  description: 'Points collected successfully via dynamic QR',
                  metadata: {'token_id': tokenId},
                );

                // Get points from metadata if available
                final metadata = newData['metadata'];
                String? pts;
                if (metadata != null && metadata is Map) {
                  pts = metadata['points']?.toString();
                }

                setState(() {
                  _isUsed = true;
                  _earnedPoints = pts;
                  _timer?.cancel();
                });

                // Fetch latest transaction for this user and redirect
                try {
                  final user = supabase.auth.currentUser;
                  if (user != null) {
                    // Give a tiny delay for DB consistency
                    await Future.delayed(const Duration(milliseconds: 500));

                    final txn = await supabase
                        .from('fuel_transactions')
                        .select()
                        .eq('user_id', user.id)
                        .order('created_at', ascending: false)
                        .limit(1)
                        .maybeSingle();

                    if (txn != null && mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FuelTransactionDetailScreen(data: txn),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  debugPrint("Error fetching follow-up transaction: $e");
                }
              }
            }
          },
        )
        .subscribe();
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
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('earn_points'.tr(locale)),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isUsed
              ? _buildSuccessView(isDark)
              : _isLoading
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
              : _errorMessage !=
                    null // Use _errorMessage
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
                      _errorMessage!, // Use _errorMessage
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Code Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'EARN|$_tokenId',
                        version: QrVersions.auto,
                        size: 240.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Instruction text
                    Text(
                      'Show this QR to the station staff\nto earn points for your purchase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Timer display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _secondsRemaining < 60
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _secondsRemaining < 60
                              ? Colors.redAccent
                              : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_secondsRemaining == 0) ...[
                      const SizedBox(height: 24),
                      Text(
                        'QR Expired - Generate a new one',
                        style: const TextStyle(color: Colors.red),
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
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
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
          _earnedPoints != null
              ? "Point $_earnedPoints မှတ် ရရှိပြီးပါပြီ"
              : "Point များ ရရှိပြီးပါပြီ",
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
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
