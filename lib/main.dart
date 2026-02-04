import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Providers/point_provider.dart';
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
      title: 'MS Loyalty',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
