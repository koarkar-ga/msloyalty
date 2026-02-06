import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:msloyalty/Constants/Config.dart';
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
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  File? _imageFile;
  bool _isOtpSent = false;
  bool _isLoading = false;
  int? _lastRequestId;
  final supabase = Supabase.instance.client;

  // ၂။ အဆင့်မြင့် OTP Request Logic
  Future<void> _requestOTP() async {
    if (!_formKey.currentState!.validate()) return; // Form မပြည့်စုံရင် ရပ်မယ်

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    try {
      // ဖုန်းနံပါတ် ရှိပြီးသားလား အရင်စစ်
      final existingUser = await supabase
          .from('profiles')
          .select('id')
          .eq('phone_number', phone)
          .maybeSingle();

      if (existingUser != null) {
        _showSnackBar("ဤဖုန်းနံပါတ်ဖြင့် အကောင့်ရှိပြီးဖြစ်ပါသည်", isError: true);
      } else {
        // SMSPoh Service ကို အသုံးပြုခြင်း
        final response = await SMSPohService.requestOTP(phone);
        print(response);
        if (response != null) {
          setState(() {
            _isOtpSent = true;
            _lastRequestId = response['requestId'];
          });
          _showSnackBar("OTP ကုဒ်ကို SMS ပို့လိုက်ပါပြီ");
        } else {
          _showSnackBar("SMS ပို့ဆောင်မှု မအောင်မြင်ပါ", isError: true);
        }
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ၃။ Verify & Navigate
  Future<void> _verifyAndNext() async {
    if (_otpController.text.length < 6) {
      _showSnackBar("OTP ၆ လုံး မှန်ကန်စွာ ရိုက်ထည့်ပါ", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // SMSPoh Verify (သင့် API Key ကို အသုံးပြုပါ)
      final verifyUrl = "https://v3.smspoh.com/api/otp/verify";
      final response = await http.post(
        Uri.parse(verifyUrl),
        body: {
          'accessToken':
              'RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ',
          'to': _phoneController.text.trim(),
          'code': _otpController.text.trim(),
          'requestId': _lastRequestId.toString(),
        },
      );

      _navigateToSetPassword();
    } catch (e) {
      _showSnackBar("Verification Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetPasswordPage(
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          imageFile: _imageFile,
        ),
      ),
    );
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
                    _buildTextField(
                      _nameController,
                      "အမည်အပြည့်အစုံ",
                      Icons.person,
                      enabled: !_isOtpSent,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      _phoneController,
                      "ဖုန်းနံပါတ်",
                      Icons.phone,
                      isPhone: true,
                      enabled: !_isOtpSent,
                    ),

                    if (_isOtpSent) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                        _otpController,
                        "OTP ၆ လုံး ရိုက်ထည့်ပါ",
                        Icons.lock_clock,
                        isOtp: true,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _requestOTP,
                          child: const Text("OTP ပြန်ပို့မည်"),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    _buildSubmitButton(),
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
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: Image.network(
              Config.logoImage, // သင့် Config ထဲက Logo URL
              height: 60,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person_add_alt_1_rounded, // Signup အတွက် အိုင်ကွန်ပြောင်းထားသည်
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
    bool isOtp = false,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isPhone || isOtp ? TextInputType.number : TextInputType.text,
      maxLength: isOtp ? 6 : (isPhone ? 11 : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1B4F72)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: !enabled,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "$label ဖြည့်သွင်းပါ";
        if (isPhone && value.length < 9) return "ဖုန်းနံပါတ် မှားယွင်းနေပါသည်";
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isOtpSent ? _verifyAndNext : _requestOTP),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isOtpSent ? "ကုဒ်စစ်ဆေးမည်" : "OTP တောင်းဆိုမည်",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }
}
