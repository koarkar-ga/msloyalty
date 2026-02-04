import 'dart:async'; // Timer အတွက် လိုအပ်သည်
import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/login_screen.dart';
import 'dart:ui';
import 'home_screen.dart'; // Home Screen ကို import လုပ်ပါ

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // စက္ကန့် ၃ စက္ကန့်အကြာတွင် Home Screen သို့ ပြောင်းမည်
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigator.pushReplacement ကိုသုံးခြင်းဖြင့်
        // နောက်ပြန်ဆုတ်လျှင် Splash Screen သို့ ပြန်မရောက်တော့ပါ
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://www.moonsungroup.com/wp-content/uploads/2024/12/88241740_1806356016162404_6870344400963108864_n.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.8),
          ),
          // Blur layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.white.withOpacity(0.2), // soft overlay
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 200, bottom: 8.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Fuel More..",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 26,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " Earn More..",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 26,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
