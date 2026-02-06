// import 'package:device_info_plus/device_info_plus.dart';
// import 'dart:io';

// import 'package:supabase_flutter/supabase_flutter.dart';

// // Future<void> _updateDeviceId(String userId) async {
// //   var deviceInfo = DeviceInfoPlugin();

// //   final supabase = Supabase.instance.client;
// //   String? deviceId;

// //   if (Platform.isAndroid) {
// //     var androidInfo = await deviceInfo.androidInfo;
// //     deviceId = androidInfo.id; // Unique ID for Android
// //   } else if (Platform.isIOS) {
// //     var iosInfo = await deviceInfo.iosInfo;
// //     deviceId = iosInfo.identifierForVendor; // Unique ID for iOS
// //   }

// //   // Supabase မှာ Device ID သွားအပ်မယ်
// //   await supabase.from('profiles').update({'last_device_id': deviceId}).eq('id', userId);

// //   // Local မှာလည်း သိမ်းထားမယ် (နောက်မှ ပြန်စစ်ဖို့)
// //   // Example: SharedPreferences.set('my_device_id', deviceId);
// // }
