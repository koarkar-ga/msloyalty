import 'package:flutter/material.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
        future: getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          final String fullName = userData?['full_name'] ?? "အမည်မရှိ";
          final String? avatarUrl = userData?['avatar_url'];

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Profile Image Section
                Center(
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFF1B4F72),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 55, color: Colors.white)
                        : null,
                  ),
                ),

                const SizedBox(height: 25),

                // User Info Section
                _buildInfoTile(Icons.person_outline, "အမည်", fullName),
                _buildInfoTile(
                  Icons.phone_android,
                  "ဖုန်းနံပါတ်",
                  userData?['phone_number'] ?? "N/A",
                ),
                _buildInfoTile(Icons.card_membership, "Member ID", userData?['member_id'] ?? "N/A"),
                _buildInfoTile(Icons.code, "Code", userData?['id'] ?? "N/A"),
                _buildInfoTile(
                  Icons.stars,
                  "စုစုပေါင်း ရမှတ်",
                  "${userData?['total_points'] ?? 0} Points",
                ),

                const Divider(height: 40),

                // Logout Button
                _buildLogoutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }
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
    title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
    ),
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
          handleForceLogout(context, prefs);
          if (context.mounted) {
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
