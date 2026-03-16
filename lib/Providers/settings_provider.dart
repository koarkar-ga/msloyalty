import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  
  ThemeMode _themeMode = ThemeMode.light;
  String _locale = 'en';
  bool _notificationsEnabled = true;
  bool _pinLockEnabled = false;

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get pinLockEnabled => _pinLockEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final isDark = prefs.getBool('isDark');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    
    final lang = prefs.getString('locale');
    if (lang != null) {
      _locale = lang;
    }

    final notiEnabled = prefs.getBool('notificationsEnabled');
    if (notiEnabled != null) {
      _notificationsEnabled = notiEnabled;
    }

    final pinEnabled = prefs.getBool('pinLockEnabled');
    if (pinEnabled != null) {
      _pinLockEnabled = pinEnabled;
    }

    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }

  // ── PIN Lock Logic ──────────────────────────────────────────────
  
  Future<void> togglePinLock(bool enabled) async {
    _pinLockEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pinLockEnabled', enabled);
    if (!enabled) {
      await _secureStorage.delete(key: 'app_pin');
    }
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: 'app_pin', value: pin);
    await togglePinLock(true);
  }

  Future<String?> getPin() async {
    return await _secureStorage.read(key: 'app_pin');
  }

  Future<bool> hasPinSet() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }
}
