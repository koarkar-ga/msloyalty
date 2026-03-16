import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/DynamicRedeemQRScreen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardDetailPage extends StatefulWidget {
  final int rewardId;
  const RewardDetailPage({super.key, required this.rewardId});

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, dynamic>> getRewardDetail() async {
    final data = await supabase.from('gift_cards').select().eq('id', widget.rewardId).single();
    return data;
    // Do something with the data
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: getRewardDetail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: MoonSunLoading());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reward details',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final reward = snapshot.data!;
          final String title = reward['title'] ?? 'Reward Detail';
          final String? imageUrl = reward['image_url'];
          final String expiry = reward['expire_date'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(reward['expire_date']))
              : 'No Expiry';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- Immersive Header ---
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF1B4F72),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(imageUrl, fit: BoxFit.cover)
                      else
                        Container(
                          color: const Color(0xFF1B4F72),
                          child: const Icon(Icons.card_giftcard, size: 80, color: Colors.white24),
                        ),
                      // Gradient Overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Content ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title & Expiry Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'MOONSUN ENERGY',
                                  style: TextStyle(
                                    color: Color(0xFF1B4F72),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.access_time_rounded, size: 14, color: subColor),
                              const SizedBox(width: 4),
                              Text(
                                expiry,
                                style: TextStyle(color: subColor, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reward['description'] ?? '',
                            style: TextStyle(color: subColor, fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Redemption Section
                    _sectionHeader('Redeem Option', Icons.card_membership_rounded, textColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B4F72),
                            const Color(0xFF1B4F72).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B4F72).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.qr_code_2_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Claim your reward',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Show this to station staff',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DynamicRedeemQRScreen(
                                      rewardId: widget.rewardId,
                                      rewardTitle: title,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1B4F72),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Claim Now',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Terms & Conditions
                    _sectionHeader('Terms & Conditions', Icons.gavel_rounded, textColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: textColor!.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        (reward['agreement'] ?? 'No terms specified.')
                            .toString()
                            .replaceAll('\\n', '\n'),
                        style: TextStyle(color: subColor, fontSize: 13, height: 1.6),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Help Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Need help? Contact support at ${reward['phone_number'] ?? '09760255836'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color? textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B4F72)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}



