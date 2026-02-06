import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/get_device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> checkUserSession(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final String? localDeviceId = prefs.getString('device_id');

  final session = Supabase.instance.client.auth.currentSession;

  // ၁။ Session မရှိရင် (သို့) Local မှာ Login status false ဖြစ်နေရင်
  if (session == null || !isLoggedIn) {
    navigateTo(context, '/login');
    return;
  }

  // ၂။ အကယ်၍ Session ရှိနေရင် Database က Device ID နဲ့ ပြန်တိုက်စစ်မယ်
  try {
    final userData = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .maybeSingle();

    if (userData != null) {
      final String userId = userData['id'];
      final String dbDeviceId = userData['last_device_id'] ?? "";
      final String currentDeviceId = (await getThisDeviceId())['device_id'] ?? "";

      print("Current Device ID: $currentDeviceId, Database Device ID: $dbDeviceId");
      print("Current User ID: $userId, Database User ID: ${userData['id']}");

      // ၃။ Database က ID နဲ့ လက်ရှိစက်ရဲ့ ID တူမှ ပေးဝင်မယ်
      if (dbDeviceId == currentDeviceId) {
        navigateTo(context, '/home');
      } else {
        // ID မတူရင် တခြားစက်မှာ ဝင်သွားပြီလို့ ယူဆပြီး အကုန်ရှင်းထုတ်မယ်
        await handleForceLogout(context, prefs);
      }
    } else {
      navigateTo(context, '/login');
    }
  } catch (e) {
    navigateTo(context, '/login');
  }
}

// Security ကြောင့် Logout လုပ်ရလျှင် Local Data ပါ ဖျက်ပစ်မည်
Future<void> handleForceLogout(BuildContext context, SharedPreferences prefs) async {
  await Supabase.instance.client.auth.signOut();
  await prefs.clear(); // Local မှာ သိမ်းထားသမျှ အကုန်ဖျက်
  navigateTo(context, '/login');
}

void navigateTo(BuildContext context, String routeName) {
  if (context.mounted) {
    Navigator.pushReplacementNamed(context, routeName);
  }
}

// ProfileScreen ရဲ့ အပေါ်မှာ ဒီ Function လေး ထည့်ပေးပါ
Future<Map<String, dynamic>?> getUserProfile() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final user = await Supabase.instance.client
      .from('profiles')
      .select('*')
      .eq('id', prefs.getString('user_id') as String)
      .maybeSingle();
  if (user == null) return null;

  return user;
}

//Save User Data Locally
Future<void> saveUserLocalData(
  String userId,
  String deviceId,
  String deviceName,
  String deviceModel,
  String deviceType,
) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_id', userId);
  await prefs.setString('device_id', deviceId);
  await prefs.setString('device_name', deviceName);
  await prefs.setString('device_model', deviceModel);
  await prefs.setString('device_type', deviceType);
  await prefs.setBool('is_logged_in', true);
}
