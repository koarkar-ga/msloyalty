import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:msloyalty/Helpers/build_login_tap_type.dart';
import 'package:msloyalty/Helpers/get_device_info.dart';
import 'package:msloyalty/Screens/signup_screen.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:msloyalty/Services/smspoh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart'; // Signup Page ကို ချိတ်ဆက်ရန်
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
  bool _isPasswordMode = true; // Default အနေနဲ့ Password နဲ့ဝင်တာကို အရင်ပြထားမယ်
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Password ကို ဖျောက်ထားရန်

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSingleDeviceLogin();
  }

  //Check Single Device Login
  Future<void> _checkSingleDeviceLogin() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select('last_device_id')
        .eq('id', user.id)
        .single();
    Map<String, dynamic> currentId = await getThisDeviceId(); // လက်ရှိစက်ရဲ့ ID ကိုယူတဲ့ function

    if (data['last_device_id'] != currentId['device_id']) {
      // ID မတူတော့ရင် Logout လုပ်မယ်
      await supabase.auth.signOut();
      if (mounted) {
        _showSecurityAlertDialog(context);
      }
      Navigator.pushReplacementNamed(context, '/login');
      _showSnackBar("ဤအကောင့်အား အခြား Device တစ်ခုတွင် အသုံးပြုလိုက်သဖြင့် Logout ဖြစ်သွားပါသည်");
    }
  }

  //Update Deivce ID
  Future<void> _updateDeviceId(
    String userId,
    String deviceId,
    String deviceName,
    String deviceModel,
    String deviceType,
    DateTime lastLoginAt,
  ) async {
    try {
      // လက်ရှိစက်ရဲ့ Unique ID ကိုယူခြင်း
      Map<String, dynamic> currentId = await getThisDeviceId();
      SharedPreferences pref = await SharedPreferences.getInstance();

      // Supabase profiles table တွင် update လုပ်ခြင်း
      await supabase
          .from('profiles')
          .update({
            'last_device_id': currentId['device_id'],
            'last_login_at': DateTime.now().toIso8601String(),
            'device_type': currentId['device_type'],
            'device_name': currentId['device_name'],
            'device_model': currentId['device_model'],
          })
          .eq('id', pref.getString('user_id') as String);

      print("Device ID Updated: ${currentId['device_id']}");
    } catch (e) {
      print("Error updating device ID: $e");
    }
  }

  //Login with Password
  void _loginWithPassword() async {
    setState(() => _isLoading = true);
    try {
      // ၁။ Supabase Auth ဖြင့် Login ဝင်ခြင်း
      final res = await supabase.auth.signInWithPassword(
        email: "${_phoneController.text}@moonsungroup.com",
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // ၃။ Local Storage တွင် User Data သိမ်းဆည်းခြင်း
        final Map<String, dynamic> currentDeviceId = await getThisDeviceId();
        final Map<String, dynamic>? userProfile = (await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('phone_number', _phoneController.text)
            .maybeSingle());

        print("User Profile: ${userProfile!['id']}");
        // ၂။ Local မှာ သိမ်းမယ်
        await saveUserLocalData(
          userProfile['id'],
          currentDeviceId['device_id'],
          currentDeviceId['device_name'],
          currentDeviceId['device_model'],
          currentDeviceId['device_type'],
        ).then(
          (value) async =>
              await _updateDeviceId(
                userProfile['id'],
                currentDeviceId['device_id'],
                currentDeviceId['device_name'],
                currentDeviceId['device_model'],
                currentDeviceId['device_type'],
                DateTime.now(),
              ).then((onData) {
                print({
                  userProfile['id'],
                  currentDeviceId['device_id'],
                  currentDeviceId['device_name'],
                  currentDeviceId['device_model'],
                  currentDeviceId['device_type'],
                });
              }),
        );

        _showSnackBar("Login အောင်မြင်ပါသည်");
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnackBar("ဖုန်းနံပါတ် သို့မဟုတ် Password မှားယွင်းနေပါသည်");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //Handle LOGIN
  void _handleLogin() async {
    if (_isPasswordMode) {
      // Password နဲ့ ဝင်ခြင်း
      _loginWithPassword();
    } else {
      if (!_isOtpSent) {
        _requestOtp();
      } else {
        _verifyOtp();
      }
    }
  }

  //Request OTP
  void _requestOtp() async {
    setState(() => _isLoading = true);

    // API Call to request OTP
    final response = await SMSPohService.requestOTP(_phoneController.text);

    // --- ဒီနေရာမှာ Supabase နဲ့ အကောင့်ရှိမရှိ စစ်ပါမယ် ---
    final existingUser = await supabase
        .from('profiles')
        .select()
        .eq('phone_number', _phoneController.text)
        .maybeSingle();

    if (existingUser != null) {
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
      // အကောင့်မရှိသေးလျှင် Signup Page သို့ ဖုန်းနံပါတ်ပါးပြီး လွှတ်လိုက်မယ်
      _showSnackBar("အကောင့်မရှိသေးသည့်အတွက် အကောင့်အရင်ဖွင့်ပေးပါ");
      _isOtpSent = false;
    }
  }

  //Verify OTP
  void _verifyOtp() async {
    final otpCode = _otpController.text;
    if (otpCode.length < 6) {
      _showSnackBar("OTP ၆ လုံးအပြည့် ရိုက်ထည့်ပါ");
      return;
    }

    setState(() => _isLoading = true);

    // SMSPoh Verify API Call
    final verifyUrl =
        "https://v3.smspoh.com/api/otp/verify?accessToken=RnJES3dfNlMyY3U0M2drOVZuNTQ4eThhMUtLWGxnLVA6aHFqYzVUN2J1NUdLRXlxR3Ita1VWUzBDUUw3bnpuamQ&to=${_phoneController.text}&code=$otpCode&requestId=$_lastRequestId";

    try {
      final response = await http.post(Uri.parse(verifyUrl));
      print(response.body);

      if (response.statusCode == 200) {
        // ၁။ Supabase Auth ဖြင့် Login ဝင်ခြင်း
        final res = await supabase
            .from('profiles')
            .select('*')
            .eq('phone_number', _phoneController.text)
            .maybeSingle();

        if (res!['phone_number'] == _phoneController.text) {
          // ၃။ Local Storage တွင် User Data သိမ်းဆည်းခြင်း
          final Map<String, dynamic> currentDeviceId = await getThisDeviceId();
          final Map<String, dynamic>? userProfile = (await Supabase.instance.client
              .from('profiles')
              .select('*')
              .eq('phone_number', _phoneController.text)
              .maybeSingle());

          print("User Profile: ${userProfile!['id']}");
          // ၂။ Local မှာ သိမ်းမယ်
          await saveUserLocalData(
            userProfile['id'],
            currentDeviceId['device_id'],
            currentDeviceId['device_name'],
            currentDeviceId['device_model'],
            currentDeviceId['device_type'],
          ).then(
            (value) async =>
                await _updateDeviceId(
                  userProfile['id'],
                  currentDeviceId['device_id'],
                  currentDeviceId['device_name'],
                  currentDeviceId['device_model'],
                  currentDeviceId['device_type'],
                  DateTime.now(),
                ).then((onData) {
                  print({
                    userProfile['id'],
                    currentDeviceId['device_id'],
                    currentDeviceId['device_name'],
                    currentDeviceId['device_model'],
                    currentDeviceId['device_type'],
                  });
                }),
          );

          _showSnackBar("Login အောင်မြင်ပါသည်");
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // အကောင့်မရှိသေးလျှင် Signup Page သို့ ဖုန်းနံပါတ်ပါးပြီး လွှတ်လိုက်မယ်
        _showSnackBar("အကောင့်မရှိသေးသည့်အတွက် အကောင့်အရင်ဖွင့်ပေးပါ");
      }
    } catch (e) {
      print(e);
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  //Show Security Alert Dialog
  void _showSecurityAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // အပြင်ကို နှိပ်ပြီး ပိတ်လို့မရအောင် လုပ်ထားမယ်
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(
                Icons.security_update_warning_rounded,
                color: Color(0xFFC62828), // MOONSUN Red
                size: 50,
              ),
              SizedBox(height: 15),
              Text(
                "Security Alert!",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
              ),
            ],
          ),
          content: const Text(
            "သင့်အကောင့်ကို အခြား Device တစ်ခုတွင် အသုံးပြုလိုက်သောကြောင့် ဤစက်မှ အလိုအလျောက် Logout ပြုလုပ်လိုက်ပါပြီ။",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog ကို ပိတ်
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "အိုကေ၊ နားလည်ပါပြီ",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
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
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
                border: Border(bottom: BorderSide(color: Color(0xFF1B4F72), width: 0.5)),
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

                  const Text(
                    "သင့်အကောင့်သို့ ဝင်ရန် နည်းလမ်းရွေးချယ်ပါ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildLoginTypeTab("Password", _isPasswordMode, () {
                        setState(() => _isPasswordMode = true);
                      }),
                      const SizedBox(width: 10),
                      buildLoginTypeTab("OTP Login", !_isPasswordMode, () {
                        setState(() => _isPasswordMode = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 5),

                  const SizedBox(height: 35),

                  Column(
                    children: [
                      // ဖုန်းနံပါတ် Field
                      TextField(
                        controller: _phoneController,
                        enabled: !_isOtpSent, // ပို့ပြီးရင် ပြင်လို့မရအောင် ပိတ်ထားမယ်
                        decoration: InputDecoration(
                          labelText: " 09 - ဖုန်းနံပါတ် ရိုက်ထည့်ပါ",
                          prefixIcon: const Icon(Icons.phone_android),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Password Mode ဖြစ်မှ Password Field ကို ပြမယ်
                      if (_isPasswordMode)
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
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
                        height: 56, // ပိုပြီး နှိပ်လို့ကောင်းအောင် height တိုးထားပါတယ်
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828), // MOONSUN Red Color
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // ခေတ်မီတဲ့ ပုံစံအတွက် curve တိုးထားပါတယ်
                            ),
                            // ခလုတ်နှိပ်လိုက်တဲ့အခါ ထွက်ပေါ်လာမယ့် အရောင် (Splashing effect)
                            shadowColor: const Color(0xFFC62828).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  // ၁။ Password Mode ဖြစ်နေရင် "အကောင့်ဝင်မည်" လို့ပြမယ်
                                  _isPasswordMode
                                      ? "အကောင့်ဝင်မည်"
                                      // ၂။ OTP Mode ဆိုရင် OTP ပို့ပြီး/မပြီးပေါ်မူတည်ပြီး စာသားပြောင်းမယ်
                                      : (_isOtpSent ? "အတည်ပြုမည်" : "OTP တောင်းဆိုမည်"),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                        ),
                      ),

                      //Phone Number ပြန်ပြင်ရန်အတွက်
                      if (_isOtpSent) ...[
                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text(
                            "ဖုန်းနံပါတ် ပြန်ပြင်ရန်",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        // ... OTP TextField ...
                      ],
                    ],
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "အကောင့်မရှိသေးဘူးလား?",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // ၁။ အကောင့်သစ်ဖွင့်ရန် Button (Outlined Style)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1B4F72), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "အကောင့်သစ်ဖွင့်ရန်",
                        style: TextStyle(
                          color: Color(0xFF1B4F72),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
