import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msloyalty/services/fifo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointProvider with ChangeNotifier {
  int _points = 0; // Total points (legacy column)
  int _activePoints = 0; // Spendable points (Active + Expiring Soon)
  int _expiringSoonPoints = 0; // Points expiring within 30 days
  String _tier = "Gold Member";
  bool _isLoading = false;

  StreamSubscription? _profileSubscription;
  bool _isListening = false;

  int get points => _points;
  int get activePoints => _activePoints;
  int get expiringSoonPoints => _expiringSoonPoints;
  bool get isLoading => _isLoading;

  final supabase = Supabase.instance.client;

  // Realtime Data နားထောင်ခြင်း
  void startListening() {
    if (_isListening) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    
    _isListening = true;
    _profileSubscription = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((List<Map<String, dynamic>> data) {
      if (data.isNotEmpty) {
        _points = data.first['total_points'] ?? 0;
        _tier = data.first['tier_level'] ?? "Gold Member";
        notifyListeners(); // Immediate notification for total points
        _fetchActivePoints();
      }
    });
  }

  Future<void> _fetchActivePoints() async {
    try {
      final summary = await FifoService.getMySummary();
      _activePoints = summary.activePoints + summary.expiringSoonPoints;
      _expiringSoonPoints = summary.expiringSoonPoints;
      notifyListeners(); // Subsequent notification for active points
    } catch (e) {
      debugPrint("Error fetching active points: $e");
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  // Database မှ Point များကို တစ်ကြိမ်တည်း ဆွဲယူခြင်း

  Future<void> fetchUserData() async {
    _isLoading = true;
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase.from('profiles').select().eq('id', userId).single();

    _points = data['total_points'] ?? 0;
    _tier = data['tier_level'] ?? "Gold Member";
    
    // Fetch active points too
    final summary = await FifoService.getMySummary();
    _activePoints = summary.activePoints + summary.expiringSoonPoints;
    _expiringSoonPoints = summary.expiringSoonPoints;

    _isLoading = false;
    notifyListeners();
  }

  // Point အသစ်ပေါင်းထည့်ခြင်း
  Future<Map<String, dynamic>?> addPoints(int earnedPoints, double spent, {String? qrCode}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    
    final userId = user.id;
    final newTotal = _points + earnedPoints;

    // 1. Profile မှာ Point update လုပ်မယ်
    await supabase.from('profiles').update({'total_points': newTotal}).eq('id', userId);

    // 2. Fuel Transaction ထဲမှာ မှတ်တမ်းသွင်းမယ် (For Receipt Voucher)
    final now = DateTime.now();
    final vocNo = 'MS-${now.millisecondsSinceEpoch}';
    
    final txnData = {
      'user_id': userId,
      'amount_mmk': spent,
      'points_earned': earnedPoints,
      'voc_no': vocNo,
      'fuel_type': 'Octane 92', // Default or from QR
      'station_id': 'ST-001',   // Default or from QR
      'sale_type': 'Cash',      // Default or from QR
      'created_at': now.toIso8601String(),
    };

    final result = await supabase.from('fuel_transactions').insert(txnData).select().single();

    // 3. Point History ထဲမှာ မှတ်တမ်းသွင်းမယ်
    await supabase.from('point_history').insert({
      'user_id': userId,
      'amount_spent': spent,
      'points_earned': earnedPoints,
      'txn_id': result['id'], // Link to fuel txn
    });

    _points = newTotal;
    notifyListeners();
    
    return result;
  }

  Future<void> submitFeedback(int txnId, int rating, String remark) async {
    final user = supabase.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] ?? 'User';

    // Update both tables for consistency
    await supabase.from('fuel_transactions').update({
      'customer_rating': rating,
      'customer_remark': remark,
    }).eq('id', txnId);

    await supabase.from('point_history').update({
      'customer_rating': rating,
      'customer_remark': remark,
    }).eq('txn_id', txnId);

    // ၃။ Dashboard အတွက် Activity log သွင်းမယ်
    try {
      await supabase.from('activities').insert({
        'action_type': 'customer_feedback',
        'description': '$fullName မှ Rating: $rating ပေးပြီး မှတ်ချက်ပေးခဲ့ပါသည်: "$remark"',
        'user_id': user?.id,
        'user_name': fullName,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'metadata': {
          'txn_id': txnId,
          'rating': rating,
          'remark': remark,
        }
      });
    } catch (e) {
      debugPrint("Failed to log feedback activity: $e");
    }
  }
}
