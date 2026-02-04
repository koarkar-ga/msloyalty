import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:developer';

import 'package:msloyalty/Constants/Config.dart';

class SMSPohService {
  // သင်၏ API Access Token ကို ဒီမှာထည့်ပါ
  static const String _accessToken =
      'RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ';
  static const String _baseUrl = "https://v3.smspoh.com/api/otp/request";

  /// OTP ပို့ရန် Function
  static Future<Map<String, dynamic>?> requestOTP(String phoneNumber) async {
    try {
      final queryParameters = {
        'from': 'MOON SUN',
        'to': phoneNumber,
        'brand': 'MOONSUN',
        'accessToken': _accessToken,
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        // JSON String ကို Map အဖြစ်ပြောင်းပြီး Return ပြန်ပေးမယ်
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(jsonDecode(response.body));
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
