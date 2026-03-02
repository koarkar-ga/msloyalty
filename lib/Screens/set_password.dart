import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/UiHelper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetPasswordPage extends StatefulWidget {
  final String phone;
  final String name;
  final String? email;
  final DateTime? dob;
  final File? imageFile;

  const SetPasswordPage({
    super.key,
    required this.phone,
    required this.name,
    required this.dob,
    required this.email,
    required this.imageFile,
  });

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _completeRegistration() async {
    if (_passwordController.text != _confirmController.text) {
      Uihelper.showSnackBar(context, "Password များ မကိုက်ညီပါ");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ၁။ Supabase Auth တွင် Register လုပ်ခြင်း
      final authRes = await supabase.auth.signUp(
        email: "${widget.phone}@moonsungroup.com",
        password: _passwordController.text.trim(),
      );

      final userId = authRes.user?.id;
      if (userId != null) {
        String? imageUrl;
        // ၂။ ပုံတင်ခြင်း
        if (widget.imageFile != null) {
          final String filePath = 'public/profile_${widget.phone}.jpg';
          await supabase.storage.from('moonsun_assets').upload(filePath, widget.imageFile!);
          imageUrl = supabase.storage.from('moonsun_assets').getPublicUrl(filePath);
        }

        // ၃။ Profile Table သိမ်းခြင်း
        await supabase.from('profiles').insert({
          'id': userId,
          'full_name': widget.name,
          'phone_number': widget.phone,
          'avatar_url': imageUrl,
          'dob': null, // Date of Birth ကို မထည့်သွင်းထားပါ
          'email': "${widget.phone}@moonsungroup.com",
          'member_id': "MS-${Random().nextInt(99999)}",
          'total_points': 500,
        });

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      Uihelper.showSnackBar(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("အကောင့်အတွက် Password သတ်မှတ်ပေးပါ"),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _completeRegistration,
                    child: const Text("Register ကို အပြီးသတ်ပါ"),
                  ),
          ],
        ),
      ),
    );
  }
}
