import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Screens/home_screen.dart';
import 'package:msloyalty/Screens/signup_screen.dart';
import 'package:msloyalty/Services/smspoh_service.dart';
import 'dart:math'; // Signup Page ကို ချိတ်ဆက်ရန်
// အရင်ကရေးခဲ့တဲ့ SMSPohService ကို import လုပ်ပါ

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false; // OTP ပို့ပြီးပြီလားဆိုတာ စစ်တဲ့ variable
  final TextEditingController _otpController = TextEditingController();
  int? _lastRequestId; // API ကပေးတဲ့ requestId ကို သိမ်းရန်

  void _handleLogin() async {
    if (!_isOtpSent) {
      setState(() => _isLoading = true);

      // API ခေါ်ယူခြင်း
      final response = await SMSPohService.requestOTP(_phoneController.text);

      setState(() => _isLoading = false);
      _showSnackBar(response.toString());

      if (response != null) {
        setState(() {
          _isOtpSent = true;
          _lastRequestId = response['requestId']; // requestId ကို သိမ်းဆည်းလိုက်ပြီ
          print("Request ID ${_lastRequestId!}");
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
        "https://v3.smspoh.com/api/otp/verify?accessToken=RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ&to=${_phoneController.text}&code=$otpCode&requestId=$_lastRequestId";
    print(verifyUrl);

    try {
      final response = await http.post(Uri.parse(verifyUrl));

      if (response.statusCode == 200) {
        // အောင်မြင်ပါက Home Screen သို့ သွားမည်
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                color: Color(0xFF1B4F72),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Center(
                child: Image.network(
                  'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
                  height: 100,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4F72),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "အကောင့်ဝင်ရန် ဖုန်းနံပါတ် ရိုက်ထည့်ပါ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 35),

                  Column(
                    children: [
                      // ဖုန်းနံပါတ် Field
                      TextField(
                        controller: _phoneController,
                        enabled: !_isOtpSent, // ပို့ပြီးရင် ပြင်လို့မရအောင် ပိတ်ထားမယ်
                        decoration: InputDecoration(
                          labelText: "ဖုန်းနံပါတ်",
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      // OTP ပို့ပြီးမှ ပေါ်လာမည့် အပိုင်း
                      if (_isOtpSent) ...[
                        const SizedBox(height: 20),
                        const Text(
                          "သင့်ဖုန်းသို့ ပို့ထားသော ၆ လုံးပါ ကုဒ်ကို ရိုက်ထည့်ပါ",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6, // OTP ၆ လုံးအတွက်
                          style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: "000000",
                            counterText: "", // စာလုံးရေတွက်တာကို ဖျောက်ထားမယ်
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1B4F72), width: 2),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      // ခလုတ်
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(_isOtpSent ? "အတည်ပြုမည်" : "OTP တောင်းဆိုမည်"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Signup Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("အကောင့်မရှိသေးဘူးလား? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupPage()),
                          );
                        },
                        child: const Text(
                          "အကောင့်သစ်ဖွင့်ရန်",
                          style: TextStyle(
                            color: Color(0xFF1B4F72),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }
}
