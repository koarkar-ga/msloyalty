import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/flip_member_card.dart';
import 'package:msloyalty/Helpers/promo_banner_slider.dart';
import 'package:msloyalty/Providers/notification_provider.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/FiFoPointHistory.dart';
import 'package:msloyalty/Screens/FiFoPointScreen.dart';
import 'package:msloyalty/Screens/fule_price_screen.dart';
import 'package:msloyalty/Screens/HistoryScreen.dart';
import 'package:msloyalty/Screens/profile_screen.dart';
import 'package:msloyalty/Screens/NearMeScreen.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:msloyalty/Screens/FuelTransactionDetailScreen.dart';
import 'package:msloyalty/Screens/notification_screen.dart';
import 'package:msloyalty/Screens/RewardScreen.dart';
import 'package:msloyalty/Screens/StatoinListScreen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  int notiCount = 0;
  late Future<Map<String, dynamic>> _userDataFuture;
  String? _qrTokenId;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserFullData();
    _generateHomeQRToken();

    // Start listening once when the home screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).startListening();
        Provider.of<PointProvider>(context, listen: false).startListening();
      }
    });
  }

  Future<void> _generateHomeQRToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final expiresAt = DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();
      final data = await supabase
          .from('qr_tokens')
          .insert({
            'user_id': user.id,
            'action_type': 'earn',
            'expires_at': expiresAt,
            'is_used': false,
          })
          .select()
          .single();
      if (mounted) {
        setState(() => _qrTokenId = data['id'].toString());
      }
    } catch (e) {
      debugPrint('Home QR token error: $e');
    }
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
      'gradient': [
        baseColor,
        baseColor.withValues(alpha: 0.7),
        baseColor.withValues(alpha: 0.9),
      ],
      'accent': Colors.white,
      'label': "$name MEMBER",
      'tagBg': Colors.white.withValues(alpha: 0.2),
      'minPoints': typeData?['min_points'] ?? 0,
    };
  }

  // Profile နှင့် Member Type Data များကို Join တွဲ၍ ရယူခြင်း
  Future<Map<String, dynamic>> _getUserFullData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'member_info': null, 'avatar_url': null, 'all_tiers': []};
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select(
            'full_name, avatar_url, member_types!inner(name, min_points, color_hex)',
          )
          .eq('id', user.id)
          .maybeSingle();

      final tiersData = await Supabase.instance.client
          .from('member_types')
          .select('name, min_points')
          .order('min_points', ascending: true);

      return {
        'full_name': data?['full_name'],
        'avatar_url': data?['avatar_url'],
        'member_info': data?['member_types'],
        'all_tiers': tiersData,
      };
    } catch (e) {
      debugPrint("Fetch Error: $e");
      return {'member_info': null, 'avatar_url': null, 'all_tiers': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final locale = settings.locale;
        return FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Center(child: MoonSunLoading()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: \${snapshot.error}')),
              );
            }
            final design = _getMemberDesign(snapshot.data?['member_info']);
            final avatarUrl = snapshot.data?['avatar_url'];
            final allTiers =
                snapshot.data?['all_tiers'] as List<dynamic>? ?? [];

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                elevation: 0,
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome'.tr(locale),
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${snapshot.data!['full_name']}",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // title: SizedBox(
                //   height: 50,
                //   width: 300,
                //   child: Row(
                //     children: [
                //       // Image.asset("assets/images/moonsun_logo.png"),
                //       const SizedBox(width: 8),
                //       Text(
                //         snapshot.data?['full_name'] ?? 'User',
                //         style: TextStyle(color: Colors.white),
                //       ),
                //     ],
                //   ),
                // ), //Image.asset("assets/images/moonsun_logo.png", height: 40),
                actions: [
                  Consumer<NotificationProvider>(
                    builder: (context, notiProvider, child) {
                      int count = notiProvider.unreadCount;

                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: Theme.of(
                                context,
                              ).appBarTheme.foregroundColor,
                            ),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/notification');
                            },
                          ),

                          // အကယ်၍ မဖတ်ရသေးသော notification ရှိမှသာ Badge ပြရန်
                          if (count > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : '$count',
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
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: design['gradient'][0],
                      backgroundImage: (avatarUrl != null)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null)
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
              body: Consumer<PointProvider>(
                builder: (context, provider, child) {
                  int currentPoints = provider.points;
                  int currentTierMin = design['minPoints'] as int? ?? 0;

                  int nextTierMin = -1;
                  String nextTierName = "";
                  for (var t in allTiers) {
                    if ((t['min_points'] as int) > currentTierMin) {
                      nextTierMin = t['min_points'];
                      nextTierName = t['name'];
                      break;
                    }
                  }

                  double progress = 1.0;
                  String progressText = "Maximum Tier Achieved";
                  if (nextTierMin > -1) {
                    int pointsNeeded = nextTierMin - currentTierMin;
                    int pointsEarned = currentPoints - currentTierMin;
                    if (pointsEarned < 0) pointsEarned = 0;
                    progress = pointsEarned / pointsNeeded;
                    if (progress > 1.0) progress = 1.0;
                    progressText =
                        "${nextTierMin - currentPoints} points to $nextTierName";
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // ✨ Flip Member Card (3D Floating Perspective)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FlipMemberCard(
                            memberName: snapshot.data?['full_name'] ?? 'Member',
                            memberId:
                                supabase.auth.currentUser?.id
                                    .substring(0, 12)
                                    .toUpperCase() ??
                                '---',
                            memberLabel: design['label'] as String,
                            gradientColors: design['gradient'] as List<Color>,
                            accentColor: design['accent'] as Color,
                            tagBg: design['tagBg'] as Color,
                            currentPoints: provider
                                .points, // Use total user points balance
                            progress: progress,
                            progressText: progressText,
                            tokenId: _qrTokenId,
                          ),
                        ),

                        // 🎁 Point Collection Reminder (Eng/MM)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B4F72), Color(0xFF2C3E50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B4F72).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.stars, color: Color(0xFFFFD700), size: 24),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Collect points after every fuel purchase!",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "ဆီဖြည့်ပြီးတိုင်း Point ရယူဖို့ မမေ့ပါနဲ့။",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ⚠️ Expiring Soon Warning
                        if (provider.expiringSoonPoints > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.shade100.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.alarm_on_rounded,
                                    color: Colors.red.shade900,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "သင့်တွင် ရက် ၃၀ အတွင်း သက်တမ်းကုန်မည့် points ${provider.expiringSoonPoints} ရှိနေပါသည်။ အမြန်ဆုံး အသုံးပြုလိုက်ပါ။",
                                      style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Menu Icons
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 4,
                                children: [
                                  _buildAction(
                                    context,
                                    Icons.local_gas_station,
                                    'station'.tr(locale),
                                    const StationListScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.card_giftcard,
                                    'reward'.tr(locale),
                                    const RewardScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.notifications_none,
                                    'notification'.tr(locale),
                                    const NotificationScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.track_changes,
                                    'pints_tracker'.tr(locale),
                                    FifoPointsPage(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.stars,
                                    'pints_status'.tr(locale),
                                    const FifoPointsScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.history,
                                    'point_history'.tr(locale),
                                    const HistoryScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.map_outlined,
                                    'near_me'.tr(locale),
                                    const NearMeScreen(),
                                  ),
                                  _buildAction(
                                    context,
                                    Icons.local_gas_station,
                                    'fuel_price'.tr(locale),
                                    const FuelPriceScreen(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 🎠 Supabase Banner Slider
                              const PromoBannerSlider(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ── Recent Transactions Header ───────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'recent_transactions_title'.tr(locale),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              ),
                              child: Text(
                                'view_all'.tr(locale),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1B4F72),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ── Recent Transactions List ─────────────────────────
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: supabase
                              .from('v_fuel_transactions_with_stations')
                              .stream(primaryKey: ['id'])
                              .eq('user_id', supabase.auth.currentUser!.id)
                              .order('created_at', ascending: false)
                              .limit(6),
                          builder: (context, transSnapshot) {
                            if (!transSnapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1B4F72),
                                  ),
                                ),
                              );
                            }
                            final transactions = transSnapshot.data!;
                            if (transactions.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No transactions found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            }
                            final textColor = Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final tx = transactions[index];
                                final date = DateTime.parse(tx['created_at']);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: settings.isDarkMode
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: settings.isDarkMode
                                            ? Colors.black.withValues(
                                                alpha: 0.3,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1B4F72,
                                        ).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.local_gas_station,
                                        color: Color(0xFF1B4F72),
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tx['fuel_type'] ?? 'Fuel Purchase',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat('dd MMM yyyy').format(date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '+${tx['points_earned']} pts',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${NumberFormat('#,###').format(tx['amount_mmk'] ?? 0)} MMK',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FuelTransactionDetailScreen(
                                                data: tx,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20), // FAB spacing
                      ],
                    ),
                  );
                },
              ),
              // floatingActionButton: const CustomScannerFAB(),
              // floatingActionButtonAnimator:
              //     FloatingActionButtonAnimator.scaling,
              // floatingActionButtonLocation:
              //     FloatingActionButtonLocation.centerFloat,
            );
          },
        );
      },
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ),
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
