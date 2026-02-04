import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Screens/login_screen.dart';
import 'dart:math';

import 'package:msloyalty/Services/smspoh_service.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false; // OTP ပို့ပြီးပြီလားဆိုတာ စစ်တဲ့ variable
  final TextEditingController _otpController = TextEditingController();
  int? _lastRequestId; // API ကပေးတဲ့ requestId ကို သိမ်းရန်

  void _handleSignup() async {
    if (!_isOtpSent) {
      setState(() => _isLoading = true);

      // API ခေါ်ယူခြင်း
      final response = await SMSPohService.requestOTP(_phoneController.text);

      setState(() => _isLoading = false);

      if (response != null) {
        setState(() {
          _isOtpSent = true;
          _lastRequestId = response['requestId']; // requestId ကို သိမ်းဆည်းလိုက်ပြီ
        });
        _showSnackBar("OTP ပို့ပြီးပါပြီ (ID: $_lastRequestId)");
      } else {
        _showSnackBar("OTP ပို့ရန် အဆင်မပြေပါ။");
      }
    } else {
      _verifyOtp();
    }
  }

  void _verifyOtp() async {
    final otpCode = _otpController.text;
    if (otpCode.length < 6) {
      _showSnackBar("OTP ၆ လုံးအပြည့် ရိုက်ထည့်ပါ");
      return;
    }

    setState(() => _isLoading = true);

    // SMSPoh Verify API Call
    // Note: RequestId ကို ပါဝင်ရပါမည်
    final verifyUrl =
        "https://v3.smspoh.com/api/otp/verify?accessToken=YOUR_TOKEN&to=${_phoneController.text}&code=$otpCode&requestId=$_lastRequestId";

    try {
      final response = await http.get(Uri.parse(verifyUrl));

      if (response.statusCode == 200) {
        // အောင်မြင်ပါက Home Screen သို့ သွားမည်
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        _showSnackBar("OTP ကုဒ် မှားယွင်းနေပါသည်။");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("အကောင့်သစ်ဖွင့်ရန်", style: TextStyle(color: Colors.black87)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Center(child: Image.network(Config.logoImage, height: 80)),
            SizedBox(height: 40),

            // အမည် ရိုက်ထည့်ရန်
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "အမည်အပြည့်အစုံ",
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),

            // ဖုန်းနံပါတ် ရိုက်ထည့်ရန်
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: "ဖုန်းနံပါတ်",
                prefixIcon: Icon(Icons.phone_android),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 30),

            // Signup Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC62828), // MOONSUN Red
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("အကောင့်ဖွင့်မည်", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
