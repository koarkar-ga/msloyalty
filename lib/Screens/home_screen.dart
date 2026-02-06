import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Helpers/open_scanner.dart';
import 'package:msloyalty/Helpers/show_my_qr_code.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  Future<String?> _getUserAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('id', user.id)
        .maybeSingle();

    return data?['avatar_url'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.network(Config.logoImage, height: 40), // Logo နေရာ
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: FutureBuilder<String?>(
              future: _getUserAvatar(),
              builder: (context, snapshot) {
                // Data ဆွဲနေတုန်းမှာ ပြမယ့် ပုံစံ
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(radius: 18, backgroundColor: Colors.grey);
                }

                final imageUrl = snapshot.data;

                return CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1B4F72),
                  // ပုံရှိရင် NetworkImage ပြမယ်၊ မရှိရင် Icon ပြမယ်
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                );
              },
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
      body: Consumer<PointProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Loyalty Card (Mockup အတိုင်း)
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF1B4F72), Color(0xFF2E86C1)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Gold Member ⭐", style: TextStyle(color: Colors.white)),
                          // Loyalty Card Widget အတွင်းရှိ QR Icon နေရာတွင်
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ShowMyQRScreen()),
                              );
                            },
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text("POINTS:", style: TextStyle(color: Colors.white70)),
                      Text(
                        "${provider.points}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.white24,
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),
                // Quick Actions (Icon လေးခု)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconBtn(Icons.location_on, "ဆိုင်ရှာရန်"),
                    _buildIconBtn(Icons.card_giftcard, "ဆုလက်ဆောင်"),
                    _buildIconBtn(Icons.history, "မှတ်တမ်း"),
                    _buildIconBtn(Icons.local_gas_station, "ဆီစျေး"),
                  ],
                ),

                SizedBox(height: 30),
                // Promo Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(Config.bannerImage),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red, // Mockup အရောင်
        child: Icon(Icons.qr_code_scanner, color: Colors.white),
        onPressed: () => OpenScanner().scanner(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.home), onPressed: () {}),
            IconButton(icon: Icon(Icons.map), onPressed: () {}),
            SizedBox(width: 40),
            IconButton(icon: Icon(Icons.account_balance_wallet), onPressed: () {}),
            IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: Color(0xFF1B4F72)),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
