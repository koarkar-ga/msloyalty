import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, dynamic>> getThisDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceId = "";
  String model = "";
  String type = Platform.isAndroid ? "Android" : "iOS";
  String name = "";

  try {
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // Android 8.0 နှင့်အထက်တွင် id သည် unique ဖြစ်သည်
      deviceId = androidInfo.id;
      model = "${androidInfo.manufacturer} ${androidInfo.model}";
      type = "Android";
      name = androidInfo.device ?? "";
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // iOS အတွက် identifierForVendor ကို သုံးသည်
      deviceId = iosInfo.identifierForVendor ?? "";
      model = iosInfo.utsname.machine ?? "iPhone";
      name = iosInfo.name ?? "";
      type = "iOS";
    }
  } catch (e) {
    print("Error getting device ID: $e");
    deviceId = "unknown_device";
  }

  return {"device_id": deviceId, "device_model": model, "device_type": type, "device_name": name};
}
