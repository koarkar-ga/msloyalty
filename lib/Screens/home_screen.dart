import 'package:flutter/material.dart';
import 'package:msloyalty/Constants/constant.dart';
import 'package:msloyalty/Helpers/custom_fab_home.dart';
import 'package:msloyalty/Helpers/dynamic_qr_reward_screen.dart';
import 'package:msloyalty/Helpers/promo_banner_slider.dart';
import 'package:msloyalty/Helpers/show_my_qr_code.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/fule_price_screen.dart';
import 'package:msloyalty/Screens/RewardScreen.dart';
import 'package:msloyalty/Screens/history_screen.dart';
import 'package:msloyalty/Screens/profile_screen.dart';
import 'package:msloyalty/Screens/station_list_screen.dart';
import 'package:msloyalty/Services/noti_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  // Stream ကို သီးသန့်ထုတ်ထားခြင်းဖြင့် UI တည်ငြိမ်စေသည်

  int notiCount = 0;
  @override
  void initState() {
    super.initState();
    // 'notifications' table မှ 'is_read' false ဖြစ်နေသည်များကို stream လုပ်ခြင်း
    // မှတ်ချက် - သင်၏ table အမည်နှင့် column အမည်ကို လိုအပ်သလို ပြင်ဆင်ပါ
    notificationStream = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('is_read', false)
        .map((List<Map<String, dynamic>> data) => data.length);
  }

  // HEX Color String မှ Flutter Color သို့ ပြောင်းလဲခြင်း
  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null) return const Color(0xFFB45309); // Default Gold
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  // Database မှ ရရှိလာသော Member Type အပေါ်မူတည်၍ UI Design ထုတ်ပေးခြင်း
  Map<String, dynamic> _getMemberDesign(Map<String, dynamic>? typeData) {
    final name = typeData?['name'] ?? 'GOLD';
    final baseColor = _getColorFromHex(typeData?['color_hex']);

    return {
      'gradient': [baseColor, baseColor.withOpacity(0.7)],
      'accent': Colors.white,
      'label': "$name MEMBER",
      'tagBg': Colors.white.withOpacity(0.2),
      'minPoints': typeData?['min_points'] ?? 0,
    };
  }

  // Profile နှင့် Member Type Data များကို Join တွဲ၍ ရယူခြင်း
  Future<Map<String, dynamic>> _getUserFullData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {'member_info': null, 'avatar_url': null};

      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, member_types!inner(name, min_points, color_hex)')
          .eq('id', user.id)
          .maybeSingle();

      return {'avatar_url': data?['avatar_url'], 'member_info': data?['member_types']};
    } catch (e) {
      debugPrint("Fetch Error: $e");
      return {'member_info': null, 'avatar_url': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserFullData(),
      builder: (context, snapshot) {
        final design = _getMemberDesign(snapshot.data?['member_info']);
        final avatarUrl = snapshot.data?['avatar_url'];

        return Scaffold(
          backgroundColor: Colors.black12,
          appBar: AppBar(
            backgroundColor: Colors.black12,
            elevation: 0,
            title: Image.asset("assets/images/moonsun_logo.png", height: 40),
            actions: [
              StreamBuilder(
                stream: notificationStream,
                builder: (context, notiSnapshot) {
                  // Noti count ကို ရယူခြင်း (data မရှိပါက 0)
                  notiCount = notiSnapshot.hasData ? notiSnapshot.data! : 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.black),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/notification');
                        },
                      ),

                      // အကယ်၍ မဖတ်ရသေးသော notification ရှိမှသာ Badge ပြရန်
                      if (notiCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              notiCount > 9 ? '9+' : '$notiCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: design['gradient'][0],
                  backgroundImage: (avatarUrl != null) ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null)
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
          body: Consumer<PointProvider>(
            builder: (context, provider, child) {
              provider.fetchUserData();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Dynamic Member Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: design['gradient'] as List<Color>,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (design['gradient'][0] as Color).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
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
                                      color: Colors.white70,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: design['tagBg'] as Color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      design['label'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => DynamicQRRewardScreen()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            "AVAILABLE POINTS",
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                          Text(
                            "${provider.points}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Dynamic Progress Bar
                          const Text(
                            "သင့်အဆင့်ကို ထိန်းသိမ်းရန် သို့မဟုတ် မြှင့်တင်ရန် ဆီဖြည့်ပါ",
                            style: TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.5, // ဤနေရာတွင် Point အလိုက် တွက်ချက်နိုင်သည်
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Menu Icons
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      children: [
                        _buildAction(
                          context,
                          Icons.location_on,
                          "ဆိုင်ရှာရန်",
                          const StationListScreen(),
                        ),
                        _buildAction(
                          context,
                          Icons.card_giftcard,
                          "ဆုလက်ဆောင်",
                          const RewardScreen(),
                        ),
                        _buildAction(context, Icons.history, "မှတ်တမ်း", const HistoryScreen()),
                        _buildAction(
                          context,
                          Icons.local_gas_station,
                          "ဆီစျေး",
                          const FuelPriceScreen(),
                        ),
                      ],
                    ),
                    PromoBannerSlider(),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: const CustomScannerFAB(),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: Icon(icon, color: const Color(0xFF1B4F72), size: 20),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
