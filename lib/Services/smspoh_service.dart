import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Helpers/showSnackBar.dart';

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

  /// OTP ကို Verify လုပ်ရန် Function
  static Future<bool> verifyOTP({
    required String phoneNumber,
    required String otp,
    required int? requestId,
  }) async {
    try {
      final verifyUrl = "https://v3.smspoh.com/api/otp/verify";
      final response = await http.post(
        Uri.parse(verifyUrl),
        body: {
          'accessToken': _accessToken,
          'to': phoneNumber,
          'code': otp,
          'requestId': requestId?.toString() ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true || data['status'] == 'true' || data['message'] == 'OTP verified successfully';
      }
      return false;
    } catch (e) {
      debugPrint("OTP Verify Error: $e");
      return false;
    }
  }

  // ၃။ Verify & Navigate
  static Future<void> verifyAndNext(
    BuildContext context,
    String otp,
    String phoneNumber,
    int? lastRequestId,
    Widget navigator,
  ) async {
    if (otp.length < 6) {
      showSnackBar(context, "OTP ၆ လုံး မှန်ကန်စွာ ရိုက်ထည့်ပါ", isError: true);
      return;
    }

    try {
      // SMSPoh Verify (သင့် API Key ကို အသုံးပြုပါ)
      final verifyUrl = "https://v3.smspoh.com/api/otp/verify";
      final response = await http.post(
        Uri.parse(verifyUrl),
        body: {
          'accessToken':
              'RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ',
          'to': phoneNumber,
          'code': otp,
          'requestId': lastRequestId,
        },
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => navigator),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => navigator),
      );
    } catch (e) {
      showSnackBar(context, "Verification Error: $e", isError: true);
    } finally {}
  }
}
