import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Providers/notification_provider.dart';
import 'package:msloyalty/Screens/pin_setup_page.dart';
import 'package:msloyalty/Screens/pin_verify_page.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:msloyalty/Services/version_service.dart';
import 'package:msloyalty/Helpers/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  Map<String, String> _systemSettings = {};

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final data = await supabase.from('system_settings').select('key, value');
      final Map<String, String> settingsMap = {};
      for (var item in data) {
        settingsMap[item['key']] = item['value'] ?? '';
      }
      if (mounted) {
        setState(() {
          _systemSettings = settingsMap;
        });
      }
    } catch (e) {
      debugPrint("Error fetching settings: $e");
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final notiProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final locale = settings.locale;
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'settings'.tr(locale),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader(
            locale == 'en' ? "PREFERENCES" : "ဦးစားပေးသတ်မှတ်ချက်များ",
          ),

          // Theme Toggle
          _buildSettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'dark_mode'.tr(locale),
            trailing: Switch(
              activeThumbColor: Colors.red,
              value: isDark,
              onChanged: (value) => settings.toggleTheme(value),
            ),
          ),

          // Notification Toggle
          _buildSettingsTile(
            icon: Icons.notifications_active_outlined,
            title: locale == 'en' ? "Notifications" : "အသိပေးချက်များ",
            trailing: Switch(
              activeThumbColor: Colors.red,
              value: settings.notificationsEnabled,
              onChanged: (value) {
                settings.toggleNotifications(value);
                notiProvider.updateNotificationPreference(value);
              },
            ),
          ),

          // Language Switcher
          _buildSettingsTile(
            icon: Icons.language_rounded,
            title: 'language'.tr(locale),
            trailing: DropdownButton<String>(
              value: locale,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'mm',
                  child: Text('မြန်မာ', style: TextStyle(fontSize: 14)),
                ),
              ],
              onChanged: (value) {
                if (value != null) settings.setLocale(value);
              },
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(locale == 'en' ? "SECURITY" : "လုံခြုံရေး"),

          // PIN Lock Toggle
          _buildSettingsTile(
            icon: Icons.lock_outline_rounded,
            title: locale == 'en' ? "PIN Lock" : "PIN ကုဒ်ဖြင့် ပိတ်ရန်",
            trailing: Switch(
              activeThumbColor: Colors.red,
              value: settings.pinLockEnabled,
              onChanged: (value) async {
                if (value) {
                  // Turning ON
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PinSetupPage(),
                    ),
                  );
                  if (result == true) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale == 'en'
                                ? "PIN Lock Enabled"
                                : "PIN ကုဒ် အောင်မြင်စွာ သတ်မှတ်ပြီးပါပြီ",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } else {
                  // Turning OFF - requires verification
                  final verified = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PinVerifyPage(),
                    ),
                  );
                  if (verified == true) {
                    await settings.togglePinLock(false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale == 'en'
                                ? "PIN Lock Disabled"
                                : "PIN ကုဒ်အား ပိတ်လိုက်ပါပြီ",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ),

          if (settings.pinLockEnabled)
            _buildSettingsTile(
              icon: Icons.password_rounded,
              title: locale == 'en' ? "Change PIN" : "PIN ကုဒ်ပြောင်းရန်",
              onTap: () async {
                // Requires verification first
                final verified = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PinVerifyPage(),
                  ),
                );
                if (verified == true) {
                  if (mounted) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSetupPage(),
                      ),
                    );
                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale == 'en'
                                ? "PIN Changed Successfully"
                                : "PIN ကုဒ် အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                }
              },
            ),

          const SizedBox(height: 24),
          _buildSectionHeader(
            locale == 'en'
                ? "INFORMATION & SUPPORT"
                : "သတင်းအချက်အလက်နှင့် အကူအညီ",
          ),

          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: locale == 'en'
                ? "Terms & Conditions"
                : "စည်းကမ်းသတ်မှတ်ချက်များ",
            onTap: () => _showDialog(
              context,
              "Terms & Conditions",
              _systemSettings['terms_conditions'] ?? "Loading...",
            ),
          ),

          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: locale == 'en'
                ? "Privacy Policy"
                : "ကိုယ်ရေးအချက်အလက် မူဝါဒ",
            onTap: () => _showDialog(
              context,
              "Privacy Policy",
              _systemSettings['privacy_policy'] ?? "Loading...",
            ),
          ),

          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: locale == 'en' ? "Help & Support" : "အကူအညီ",
            onTap: () => _showDialog(
              context,
              "Help & Support",
              _systemSettings['help_content'] ?? "Loading...",
            ),
          ),

          const SizedBox(height: 24),
          _buildSettingsTile(
            icon: Icons.update_rounded,
            title: locale == 'en'
                ? "Check for Update"
                : "အသစ်ထွက်ရှိမှု စစ်ဆေးရန်",
            onTap: () async {
              final result = await VersionService.checkUpdate();
              if (result['available'] == true) {
                if (mounted) UpdateDialog.show(context, result['version']);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        locale == 'en'
                            ? "You are using the latest version"
                            : "သင်သည် နောက်ဆုံးဗားရှင်းကို အသုံးပြုနေသည်",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return Text(
                  "${locale == 'en' ? 'App Version' : 'ဗားရှင်း'} $version+$build",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ),
          const SizedBox(height: 80), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.red, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                : null),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Scrollbar(
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
