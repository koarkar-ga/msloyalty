import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Constants/constant.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/showSnackBar.dart';
import 'package:msloyalty/Screens/OtpRequestScreen.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:msloyalty/Services/smspoh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msloyalty/Services/activity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:msloyalty/Screens/MyVehiclesScreen.dart';
import 'package:msloyalty/Services/notification_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool isOtpSent = false;
  int? lastOtpRequestId = 0;

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      await Supabase.instance.client.storage
          .from('moonsun_assets')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = Supabase.instance.client.storage
          .from('moonsun_assets')
          .getPublicUrl(filePath);

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile ပုံ ပြောင်းလဲခြင်း အောင်မြင်ပါသည်'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return await Supabase.instance.client
        .from('profiles')
        .select('*, member_types(name)')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final locale = settings.locale;
        final isDark = settings.isDarkMode;
        final fgColor = Theme.of(context).appBarTheme.foregroundColor;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;
        final subColor = Theme.of(context).textTheme.bodyMedium?.color;
        final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'profile'.tr(locale),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: fgColor,
            elevation: 0,
            actions: [
              // 🌐 Language Toggle: EN ↔ MM
              GestureDetector(
                onTap: () => settings.setLocale(locale == 'en' ? 'mm' : 'en'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4F72).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1B4F72).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    locale == 'en' ? 'EN' : 'MM',
                    style: const TextStyle(
                      color: Color(0xFF1B4F72),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // 🌙 Theme Toggle
              IconButton(
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: fgColor,
                    size: 22,
                  ),
                ),
                onPressed: () => settings.toggleTheme(!isDark),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: FutureBuilder<Map<String, dynamic>?>(
            future: _getUserProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isUploading) {
                return Center(child: MoonSunLoading());
              }

              final userData = snapshot.data;
              final String fullName = userData?['full_name'] ?? 'N/A';
              final String? avatarUrl = userData?['avatar_url'];
              final String phoneNumber = userData?['phone_number'] ?? 'N/A';
              final String email = userData?['email'] ?? 'N/A';
              final String memberType =
                  userData?['member_types']?['name'] ?? 'GOLD';
              final String memberId = userData?['member_id'] ?? 'N/A';
              final int totalPoints = userData?['total_points'] ?? 0;

              DateTime dob = (userData?['dob'] != null)
                  ? DateTime.parse(userData!['dob'])
                  : DateTime.now();
              int age = (DateTime.now().difference(dob).inDays / 365.25)
                  .floor();
              String dobDisplay = userData?['dob'] != null
                  ? '${DateFormat("dd MMM yyyy").format(dob)}  ($age yrs)'
                  : 'N/A';

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // ── Avatar Header Card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B4F72), Color(0xFF154360)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1B4F72,
                            ).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white38,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.white12,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black38,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploading
                                      ? null
                                      : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Color(0xFF1B4F72),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$memberType MEMBER',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Points row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statChip(
                                Icons.stars_rounded,
                                '$totalPoints',
                                'Points',
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.white24,
                              ),
                              _statChip(
                                Icons.badge_outlined,
                                memberId,
                                'Member ID',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Info Card ────────────────────────────────────────
                    _sectionCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        _infoTile(
                          context,
                          icon: Icons.person_outline,
                          label: locale == 'en' ? 'Full Name' : 'အမည်',
                          value: fullName,
                          textColor: textColor,
                          subColor: subColor,
                          onEdit: () =>
                              _editData(context, 'Fullname', fullName),
                        ),
                        _divider(isDark),
                        _infoTile(
                          context,
                          icon: Icons.phone_android,
                          label: locale == 'en' ? 'Phone' : 'ဖုန်းနံပါတ်',
                          value: phoneNumber,
                          textColor: textColor,
                          subColor: subColor,
                          onEdit: () =>
                              _editData(context, 'phone_number', phoneNumber),
                        ),
                        _divider(isDark),
                        _infoTile(
                          context,
                          icon: Icons.email_outlined,
                          label: locale == 'en' ? 'Email' : 'အီးမေးလ်',
                          value: email,
                          textColor: textColor,
                          subColor: subColor,
                          onEdit: () => _editData(context, 'Email', email),
                        ),
                        _divider(isDark),
                        _infoTile(
                          context,
                          icon: Icons.cake_outlined,
                          label: locale == 'en'
                              ? 'Date of Birth'
                              : 'မွေးသက္ကရာဇ်',
                          value: dobDisplay,
                          textColor: textColor,
                          subColor: subColor,
                          onEdit: () => _editData(
                            context,
                            'DOB',
                            userData?['dob'] != null
                                ? DateFormat('dd-MM-yyyy').format(dob)
                                : '',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Vehicle Card ─────────────────────────────────────
                    _sectionCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      children: [
                        _buildProfileTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Test Notification',
                          subtitle: 'Verify if notifications work',
                          onTap: () async {
                            final ns = NotificationService();
                            await ns.showTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Test notification sent!')),
                              );
                            }
                          },
                        ),
                        _divider(isDark),
                        _buildProfileTile(
                          icon: Icons.directions_car_outlined,
                          title: locale == 'en' ? 'My Vehicles' : 'ကျွန်ုပ်၏ယာဉ်များ',
                          subtitle: 'Manage and set reminders',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyVehiclesScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Logout Button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Log Logout Activity
                          await ActivityService.logActivity(
                            actionType: 'logout',
                            description: 'User logged out from mobile app',
                          );
                          await Supabase.instance.client.auth.signOut();
                          final prefs = await SharedPreferences.getInstance();
                          if (context.mounted) {
                            handleForceLogout(context, prefs);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (r) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: Text('logout'.tr(locale)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────

  Widget _statChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF1B4F72)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _sectionCard({
    required Color cardBg,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 56,
    color: isDark ? Colors.white12 : Colors.black12,
  );

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? textColor,
    Color? subColor,
    VoidCallback? onEdit,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: const Color(0xFF1B4F72), size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 11, color: subColor)),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: onEdit != null
          ? IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1B4F72),
                size: 18,
              ),
              onPressed: onEdit,
              tooltip: 'ပြင်ဆင်ရန်',
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            )
          : null,
    );
  }

  // ── Edit Dialog ─────────────────────────────────────────────────────────

  Future<void> checkPhoneNumber(
    String phoneNumber,
    bool isOtpSent,
    int? lastRequestId,
  ) async {
    try {
      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (existingUser != null) {
        showSnackBar(
          context,
          'ဤဖုန်းနံပါတ်ဖြင့် အကောင့်ရှိပြီးဖြစ်ပါသည်',
          isError: true,
        );
      } else {
        final response = await SMSPohService.requestOTP(phoneNumber);
        if (response != null) {
          setState(() {
            this.isOtpSent = true;
            lastOtpRequestId = response['requestId'];
          });
          showSnackBar(context, 'OTP ကုဒ်ကို SMS ပို့လိုက်ပါပြီ');
        } else {
          showSnackBar(context, 'SMS ပို့ဆောင်မှု မအောင်မြင်ပါ', isError: true);
        }
      }
    } catch (e) {}
  }

  void _editData(BuildContext context, String title, String previousData) {
    final TextEditingController ctrl = TextEditingController(
      text: previousData,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ပြင်ဆင်ရန် - $title',
          style: const TextStyle(fontSize: 15),
        ),
        content: title == 'DOB'
            ? buildDateField(context, ctrl)
            : TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: title,
                  border: const OutlineInputBorder(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: title.toLowerCase() == 'phone_number'
                ? () {
                    checkPhoneNumber(
                      ctrl.text.trim(),
                      isOtpSent,
                      lastOtpRequestId,
                    );
                    if (isOtpSent) {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => OtpScreen(
                            phone: ctrl.text.trim(),
                            requestId: lastOtpRequestId,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(ctx).pop();
                    }
                  }
                : () async {
                    final val = ctrl.text.trim();
                    if (val.isEmpty) return;
                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) return;
                      await Supabase.instance.client
                          .from('profiles')
                          .update({title.toLowerCase(): val})
                          .eq('id', user.id);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully updated'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {});
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
