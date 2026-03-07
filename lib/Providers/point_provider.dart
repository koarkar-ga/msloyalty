import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PointProvider with ChangeNotifier {
  int _points = 0;
  String _tier = "Gold Member";
  bool _isLoading = false;

  int get points => _points;
  bool get isLoading => _isLoading;

  final supabase = Supabase.instance.client;

  // Database မှ Point များကို ဆွဲယူခြင်း
  Future<void> fetchUserData() async {
    _isLoading = true;
    final userId = supabase.auth.currentUser!.id;
    final data = await supabase.from('profiles').select().eq('id', userId).single();

    _points = data['total_points'];
    _tier = data['tier_level'];
    _isLoading = false;
    notifyListeners();
  }

  // Point အသစ်ပေါင်းထည့်ခြင်း
  Future<void> addPoints(int earnedPoints, double spent) async {
    final userId = supabase.auth.currentUser!.id;
    final newTotal = _points + earnedPoints;

    // 1. Profile မှာ Point update လုပ်မယ်
    await supabase.from('profiles').update({'total_points': newTotal}).eq('id', userId);

    // 2. Point History ထဲမှာ မှတ်တမ်းသွင်းမယ်
    await supabase.from('point_history').insert({
      'user_id': userId,
      'amount_spent': spent,
      'points_earned': earnedPoints,
    });

    _points = newTotal;
    notifyListeners();
  }
}
