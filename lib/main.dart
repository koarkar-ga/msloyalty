import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/home_screen.dart';
import 'package:msloyalty/Screens/login_screen.dart';
import 'package:msloyalty/Screens/signup_screen.dart';
import 'package:msloyalty/Screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.anonKey);

  runApp(ChangeNotifierProvider(create: (context) => PointProvider(), child: const MSLoyaltyApp()));
}

class MSLoyaltyApp extends StatelessWidget {
  const MSLoyaltyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOONSUN Energy',
      theme: ThemeData(primarySwatch: Colors.blue),
      // စတင်မည့် မျက်နှာပြင် (ဥပမာ- Signup Page ကနေ စမယ်ဆိုလျှင်)
      initialRoute: '/',

      // Route များကို ဒီနေရာမှာ စာရင်းသွင်းရပါမယ်
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignupPage(),
      },
    );
  }
}
