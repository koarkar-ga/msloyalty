import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Constants/constant.dart';
import 'package:msloyalty/Helpers/showSnackBar.dart';
import 'package:msloyalty/Screens/OtpRequestScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Screens/set_password.dart';
import 'package:msloyalty/Services/smspoh_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>(); // Validation အတွက်
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  File? _imageFile;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _isActive = false;
  int? lastRequestId;
  final supabase = Supabase.instance.client;

  // ၂။ အဆင့်မြင့် OTP Request Logic
  Future<void> _checkPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return; // Form မပြည့်စုံရင် ရပ်မယ်

    setState(() {
      _isLoading = true;
      _isActive = false;
    });
    final phone = _phoneController.text.trim();

    try {
      // ဖုန်းနံပါတ် ရှိပြီးသားလား အရင်စစ်
      final existingUser = await supabase
          .from('profiles')
          .select('id')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingUser != null) {
        showSnackBar(
          context,
          "ဤဖုန်းနံပါတ်ဖြင့် အကောင့်ရှိပြီးဖြစ်ပါသည်",
          isError: true,
        );
      } else {
        // SMSPoh Service ကို အသုံးပြုခြင်း
        final response = await SMSPohService.requestOTP(phone);
        print(response);
        if (response != null) {
          setState(() {
            _isOtpSent = true;
            lastRequestId = response['requestId'];
          });
          // ignore: use_build_context_synchronously
          showSnackBar(context, "OTP ကုဒ်ကို SMS ပို့လိုက်ပါပြီ");
          Navigator.push(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OtpScreen(phone: phone, requestId: lastRequestId),
            ),
          );
        } else {
          showSnackBar(context, "SMS ပို့ဆောင်မှု မအောင်မြင်ပါ", isError: true);
        }
      }
    } catch (e) {
      showSnackBar(context, "Error: $e", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _isActive = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Account",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B4F72),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    buildTextField(
                      _nameController,
                      "Username",
                      Icons.person,
                      enabled: !_isOtpSent,
                    ),
                    const SizedBox(height: 20),
                    buildEmailField(_emailController),
                    const SizedBox(height: 20),
                    buildDateField(context, _dobController),
                    const SizedBox(height: 20),
                    buildTextField(
                      _phoneController,
                      "Phone Number",
                      Icons.phone,
                      isPhone: true,
                      enabled: !_isOtpSent,
                    ),

                    const SizedBox(height: 40),
                    MaterialButton(
                      color: const Color(0xFF1B4F72),
                      disabledColor: Colors
                          .grey[300], // Disable ဖြစ်နေချိန်မှာ ပြမယ့်အရောင်
                      disabledTextColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 30,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoading = true;
                              });
                              _checkPhoneNumber();
                            }, //_isOtpSent ? _verifyOtp : _checkPhoneNumber,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoading
                              ? Row(
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      "OTP ပေးပို့နေပါသည်...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _isOtpSent
                                      ? "OTP ပြန်ပို့မည်"
                                      : "OTP တောင်းဆိုမည်",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          const SizedBox(width: 8),
                          const Icon(Icons.send, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1B4F72),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ၁။ Logo ပြမည့်နေရာ (LoginScreen နှင့် ပုံစံတူ)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.network(
              Config.logoImage, // သင့် Config ထဲက Logo URL
              height: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons
                    .person_add_alt_1_rounded, // Signup အတွက် အိုင်ကွန်ပြောင်းထားသည်
                size: 50,
                color: Color(0xFF1B4F72),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ၂။ Signup အတွက် သင့်တော်သော စာသား
          const Text(
            "Create New Account",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "အဖွဲ့ဝင်အသစ်အဖြစ် စာရင်းသွင်းပါ",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
