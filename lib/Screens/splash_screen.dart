import 'package:flutter/material.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // Logo ကို အနည်းဆုံး ၂ စက္ကန့်လောက် ပြထားချင်လို့ပါ
    await Future.delayed(const Duration(seconds: 2));
    print("Splash Screen Finished");
    checkUserSession(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4F72), // Brand Color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // သင်၏ Logo
            Image.network(
              'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
              width: 150,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
