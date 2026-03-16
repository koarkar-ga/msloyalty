import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/RewardScreen.dart';
import 'package:msloyalty/Screens/StatoinListScreen.dart';
import 'package:msloyalty/Screens/home_screen.dart';
import 'package:msloyalty/Providers/notification_provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Screens/notification_screen.dart';
import 'package:msloyalty/Screens/profile_screen.dart';
import 'package:msloyalty/Screens/settings_screen.dart';
import 'package:msloyalty/Services/notification_service.dart';
import 'package:msloyalty/Services/version_service.dart';
import 'package:provider/provider.dart';

// LoyaltyApp - Inner app shell (no MaterialApp - inherits theme from MSLoyaltyApp)
class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // No inner MaterialApp here - theme comes from the outer MSLoyaltyApp in main.dart
    return const MainNavigationScreen();
  }
}

// MARK: - Main Navigation Controller
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Initialize Notification Service
  final notificationService = NotificationService();
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await notificationService.init();
    // Start listening to notifications once when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final notiProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      notiProvider.updateNotificationPreference(settings.notificationsEnabled);
      notiProvider.startListening();

      // VersionService.checkVersionAndShowDialog(context);
    });
  }

  // ပြသချင်တဲ့ Screen စာရင်းများ
  final List<Widget> _screens = [
    const HomeScreen(),
    const StationListScreen(),
    const RewardScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notiProvider, child) {
          int count = notiProvider.unreadCount;

          return Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(canvasColor: Colors.transparent),
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      selectedItemColor: Colors.red,
                      unselectedItemColor: Colors.white.withOpacity(0.6),
                      selectedFontSize: 11,
                      unselectedFontSize: 11,
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          label: "Home",
                          activeIcon: Icon(Icons.home, color: Colors.red),
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.local_gas_station_outlined),
                          label: "Station",
                          activeIcon: Icon(
                            Icons.local_gas_station,
                            color: Colors.red,
                          ),
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.card_giftcard_outlined),
                          label: "Reward",
                          activeIcon: Icon(
                            Icons.card_giftcard,
                            color: Colors.red,
                          ),
                        ),
                        BottomNavigationBarItem(
                          icon: Badge(
                            label: count > 9
                                ? const Text('9+')
                                : Text('$count'),
                            isLabelVisible: count > 0,
                            child: const Icon(Icons.notifications_outlined),
                          ),
                          label: "Notification",
                          activeIcon: Icon(
                            Icons.notifications,
                            color: Colors.red,
                          ),
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.person_outline),
                          label: "Profile",
                          activeIcon: Icon(Icons.person, color: Colors.red),
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.settings_outlined),
                          label: "Settings",
                          activeIcon: Icon(Icons.settings, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
