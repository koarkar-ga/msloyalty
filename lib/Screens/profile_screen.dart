import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Constants/constant.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/MoonSunLogoAnimation.dart';
import 'package:msloyalty/Helpers/showSnackBar.dart';
import 'package:msloyalty/Helpers/upload_photo.dart';
import 'package:msloyalty/Screens/OtpRequestScreen.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:msloyalty/Services/smspoh_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Profile Image ကို Gallery မှ ရွေးချယ်ပြီး Supabase သို့ တင်ခြင်း
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
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Supabase Storage သို့ Upload တင်ခြင်း
      await Supabase.instance.client.storage
          .from('moonsun_assets')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Public URL ရယူခြင်း
      final String publicUrl = Supabase.instance.client.storage
          .from('moonsun_assets')
          .getPublicUrl(filePath);

      // Profile Table တွင် URL အသစ်ကို Update လုပ်ခြင်း
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile ပုံ ပြောင်းလဲခြင်း အောင်မြင်ပါသည်"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text("ကိုယ်ရေးအကျဉ်း", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
            return Center(child: MoonSunLoading());
          }

          final userData = snapshot.data;
          print(userData);
          final String fullName = userData?['full_name'] ?? "N/A";
          final String? avatarUrl = userData?['avatar_url'];
          final String phoneNumber = userData?['phone_number'] ?? "N/A";
          final String email = userData?['email'] ?? "N/A";
          DateTime dob = userData!['dob'] == null
              ? DateTime.now()
              : DateTime.parse(userData!['dob']);
          final String memberType = userData?['member_types']?['name'] ?? "GOLD";

          // 1. String ကို DateTime object အဖြစ်ပြောင်းခြင်း
          DateTime birthDate = userData!['dob'] == null
              ? DateTime.now()
              : DateTime.parse(userData!['dob']);

          // 2. လက်ရှိအချိန်နှင့် နှုတ်ခြင်း (Result is a Duration object)
          Duration difference = DateTime.now().difference(birthDate);

          // 3. အသက်ကို နှစ်အလိုက် တွက်ချက်ခြင်း (ခန့်မှန်းခြေ 365.25 ရက်ဖြင့်စား)
          int years = (difference.inDays / 365.25).floor();
          print(years);

          // ပိုမိုတိကျသော တွက်ချက်မှု (နှစ်၊ လ၊ ရက် ခွဲထုတ်ခြင်း)
          int daysRemaining = difference.inDays % 365;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFF1B4F72),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? const Icon(Icons.person, size: 55, color: Colors.white)
                            : null,
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1B4F72),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                _buildInfoTile(
                  Icons.person_outline,
                  "Name",
                  fullName,
                  onEdit: () => _editData(context, "Fullname", fullName),
                ),
                _buildInfoTile(
                  Icons.phone_android,
                  "Phone",
                  phoneNumber,
                  onEdit: () => _editData(context, "phone_number", phoneNumber),
                ),
                _buildInfoTile(
                  Icons.email_outlined,
                  "Email",
                  email ?? "N/A",
                  onEdit: () => _editData(context, "Email", email),
                ),
                _buildInfoTile(
                  Icons.calendar_month_outlined,
                  "DOB",
                  years != 0
                      ? "${DateFormat("dd-MM-yyyy").format(dob).toString()}  -- ($years)"
                      : "N/A",
                  onEdit: () => _editData(
                    context,
                    "DOB",
                    "${DateFormat("dd-MM-yyyy").format(dob).toString()}",
                  ),
                ),
                _buildInfoTile(Icons.card_membership, "Member ID", userData?['member_id'] ?? "N/A"),
                _buildInfoTile(Icons.workspace_premium, "Member Type", "$memberType MEMBER"),
                _buildInfoTile(Icons.stars, "Points", "${userData?['total_points'] ?? 0} Points"),
                const Divider(height: 40),
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value, {
    VoidCallback? onEdit, // Edit function အတွက် parameter
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4F72).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1B4F72)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      // ညာဘက်အစွန်တွင် Edit Button ထည့်သွင်းခြင်း
      trailing: onEdit != null
          ? IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1B4F72), size: 20),
              onPressed: onEdit,
              tooltip: "ပြင်ဆင်ရန်",
              constraints: const BoxConstraints(), // Padding လျှော့ချရန်
              padding: EdgeInsets.zero,
            )
          : null,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            if (context.mounted) {
              handleForceLogout(context, prefs);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text("အကောင့်မှ ထွက်ရန်"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Future<void> checkPhoneNumber(String phoneNumber, bool isOtpSent, int? lastRequestId) async {
    try {
      // ဖုန်းနံပါတ် ရှိပြီးသားလား အရင်စစ်
      final existingUser = await supabase
          .from('profiles')
          .select('id')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (existingUser != null) {
        showSnackBar(context, "ဤဖုန်းနံပါတ်ဖြင့် အကောင့်ရှိပြီးဖြစ်ပါသည်", isError: true);
      } else {
        // SMSPoh Service ကို အသုံးပြုခြင်း
        final response = await SMSPohService.requestOTP(phoneNumber);
        print(response);
        if (response != null) {
          setState(() {
            isOtpSent = true;
            lastRequestId = response['requestId'];
          });

          // ignore: use_build_context_synchronously
          showSnackBar(context, "OTP ကုဒ်ကို SMS ပို့လိုက်ပါပြီ");
        } else {
          // ignore: use_build_context_synchronously
          showSnackBar(context, "SMS ပို့ဆောင်မှု မအောင်မြင်ပါ", isError: true);
        }
      }
    } catch (e) {}
  }

  void _editData(BuildContext context, String title, String previousData) {
    final TextEditingController _textController = TextEditingController(text: '$previousData');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("ပြင်ဆင်ရန်"),
          content: title == 'DOB'
              ? buildDateField(context, _textController)
              : TextField(
                  controller: _textController,
                  decoration: InputDecoration(labelText: title, border: OutlineInputBorder()),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancle")),
            ElevatedButton(
              onPressed: title.toLowerCase() == "phone_number"
                  ? () {
                      checkPhoneNumber(_textController.text.trim(), isOtpSent, lastOtpRequestId);
                      isOtpSent
                          ? Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => OtpScreen(
                                  phone: _textController.text.trim(),
                                  requestId: lastOtpRequestId,
                                ),
                              ),
                            )
                          : Navigator.of(context).pop();
                    }
                  : () async {
                      final updateData = _textController.text.trim();
                      if (updateData.isEmpty) return;

                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) return;

                        await Supabase.instance.client
                            .from('profiles')
                            .update({title.toLowerCase(): updateData})
                            .eq('id', user.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Successfully updated"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {});
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        print("Error updating name: ${e.toString()}");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error updating name: ${e.toString()}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
