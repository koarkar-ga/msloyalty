import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:msloyalty/Services/security_service.dart';
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
          .from('profiles')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Public URL ရယူခြင်း
      final String publicUrl = Supabase.instance.client.storage
          .from('profiles')
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
      appBar: AppBar(
        title: const Text("ကိုယ်ရေးအကျဉ်း", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isUploading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          final String fullName = userData?['full_name'] ?? "အမည်မရှိ";
          final String? avatarUrl = userData?['avatar_url'];
          final String memberType = userData?['member_types']?['name'] ?? "GOLD";

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
                _buildInfoTile(Icons.person_outline, "အမည်", fullName),
                _buildInfoTile(
                  Icons.phone_android,
                  "ဖုန်းနံပါတ်",
                  userData?['phone_number'] ?? "N/A",
                ),
                _buildInfoTile(Icons.card_membership, "Member ID", userData?['member_id'] ?? "N/A"),
                _buildInfoTile(Icons.workspace_premium, "အဖွဲ့ဝင်အဆင့်", "$memberType MEMBER"),
                _buildInfoTile(
                  Icons.stars,
                  "လက်ရှိ ရမှတ်",
                  "${userData?['total_points'] ?? 0} Points",
                ),
                const Divider(height: 40),
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
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
}
