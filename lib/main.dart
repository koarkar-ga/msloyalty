import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Screens/settings_screen.dart';
import 'package:msloyalty/AppScreen.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Providers/notification_provider.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/home_screen.dart';

import 'package:msloyalty/Screens/intro_video_screen.dart';
import 'package:msloyalty/Screens/login_screen.dart';
import 'package:msloyalty/Screens/notification_screen.dart';
import 'package:msloyalty/Screens/signup_screen.dart';
import 'package:msloyalty/Screens/splash_screen.dart';
import 'package:msloyalty/Services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Supabase.initialize(url: Config.supabaseUrl, anonKey: Config.anonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PointProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MSLoyaltyApp(),
    ),
  );
}

class MSLoyaltyApp extends StatelessWidget {
  const MSLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOONSUN Energy',
      themeMode: settings.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4F72),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.white,
          textColor: Colors.black87,
          iconColor: Color(0xFF1B4F72),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1B4F72)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF1B4F72)),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1B4F72),
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4F72),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xFF1E1E1E),
          textColor: Colors.white,
          iconColor: Colors.lightBlueAccent,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF2C2C2C)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlueAccent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.lightBlueAccent),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.lightBlueAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // စတင်မည့် မျက်နှာပြင် (ဥပမာ- Signup Page ကနေ စမယ်ဆိုလျှင်)
      initialRoute: '/',

      // Route များကို ဒီနေရာမှာ စာရင်းသွင်းရပါမယ်
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/app': (context) => const LoyaltyApp(),
        '/home': (context) => const HomeScreen(),
        '/intro': (context) => const IntroVideoScreen(),
        '/signup': (context) => const SignupPage(),
        '/notification': (context) => const NotificationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
