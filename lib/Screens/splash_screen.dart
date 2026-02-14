import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLogoAnimation.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    // Logo ကို အနည်းဆုံး ၂ စက္ကန့်လောက် ပြထားချင်လို့ပါ
    // For Ring Rotation
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // For Text Pulsing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startInitialization();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
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
            MoonSunLogoLoadingAnimator(controller: _controller, pulseController: _pulseController),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
