import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/Config.dart';
import 'package:msloyalty/Helpers/open_scanner.dart';
import 'package:msloyalty/Helpers/promo_banner_slider.dart';
import 'package:msloyalty/Helpers/show_my_qr_code.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/fule_price_screen.dart';
import 'package:msloyalty/Screens/gift_card_voucher.dart';
import 'package:msloyalty/Screens/history_screen.dart';
import 'package:msloyalty/Screens/profile_screen.dart';
import 'package:msloyalty/Screens/station_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        title: Container(
          child: Column(
            children: [Image.asset("assets/images/moonsun_logo.png", height: 50, width: 50)],
          ),
        ),
        automaticallyImplyLeading: false,
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
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                // Loyalty Card (Mockup အတိုင်း)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    // ပိုမို Premium ဖြစ်သော Gradient အရောင်
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B4F72), Color(0xFF0D2B40)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4F72).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    // Background မှာ အလှဆင်ဖို့ Stack သုံးထားပါတယ်
                    children: [
                      // Card Background Decoration (အဝိုင်းပုံစံ အလင်းရောင်)
                      Positioned(
                        right: -10,
                        top: -10,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "MOONSUN ENERGY",
                                    style: TextStyle(
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                                    ),
                                    child: const Text(
                                      "GOLD MEMBER ⭐",
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // QR Icon with Glow Effect
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ShowMyQRScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            "TOTAL POINTS",
                            style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "${provider.points}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "PTS",
                                style: TextStyle(color: Colors.white60, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Progress Bar with Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Platinum အဆင့်သို့ရောက်ရန် 400 pts လိုပါသည်",
                                style: TextStyle(color: Colors.white54, fontSize: 10),
                              ),
                              Text(
                                "60%",
                                style: TextStyle(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.6,
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),
                // Quick Actions (Icon လေးခု)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconBtn(context, Icons.location_on, "ဆိုင်ရှာရန်", StationListScreen()),
                    _buildIconBtn(context, Icons.card_giftcard, "ဆုလက်ဆောင်", GiftCardScreen()),
                    _buildIconBtn(context, Icons.history, "မှတ်တမ်း", HistoryScreen()),
                    _buildIconBtn(context, Icons.local_gas_station, "ဆီစျေး", FuelPriceScreen()),
                  ],
                ),

                SizedBox(height: 30),

                // Promo Banner
                PromoBannerSlider(),
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
      // bottomNavigationBar: BottomAppBar(
      //   shape: CircularNotchedRectangle(),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     children: [
      //       IconButton(icon: Icon(Icons.home), onPressed: () {}),
      //       IconButton(icon: Icon(Icons.map), onPressed: () {}),
      //       SizedBox(width: 40),
      //       IconButton(icon: Icon(Icons.account_balance_wallet), onPressed: () {}),
      //       IconButton(icon: Icon(Icons.settings), onPressed: () {}),
      //     ],
      //   ),
      // ),
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case "ဆိုင်ရှာရန်":
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            break;
          case "ဆုလက်ဆောင်":
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            break;
          case "မှတ်တမ်း":
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            break;
          case "ဆီစျေး":
            Navigator.push(context, MaterialPageRoute(builder: (context) => page));
            break;
          default:
            break;
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: Icon(icon, color: Color(0xFF1B4F72)),
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
