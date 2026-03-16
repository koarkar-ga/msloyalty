import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/RewardDetailScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<dynamic> giftCards = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchGiftCards();
  }

  Future<void> _fetchGiftCards() async {
    try {
      final data = await supabase
          .from('gift_cards')
          .select()
          .eq('is_available', true);
      if (mounted) {
        setState(() {
          giftCards = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching cards: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return giftCards;
    return giftCards
        .where(
          (c) => (c['title'] as String? ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        title: const Text(
          'Rewards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search rewards...',
                hintStyle: TextStyle(color: subColor),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: MoonSunLoading())
          : _filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 64, color: subColor),
                  const SizedBox(height: 16),
                  Text(
                    'No rewards found',
                    style: TextStyle(color: subColor, fontSize: 16),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                return _buildGiftCard(
                  _filtered[index],
                  cardBg,
                  textColor,
                  subColor,
                  isDark,
                );
              },
            ),
    );
  }

  Widget _buildGiftCard(
    dynamic item,
    Color cardBg,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    final int pts = (item['points_required'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RewardDetailPage(rewardId: item['id']),
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image / Placeholder
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background gradient shimmer
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF2A3A5C),
                                    const Color(0xFF1B2D45),
                                  ]
                                : [
                                    const Color(0xFFE8F4FD),
                                    const Color(0xFFD1E9F6),
                                  ],
                          ),
                        ),
                      ),
                      if (item['image_url'] != null)
                        Image.network(
                          item['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _placeholder(isDark),
                        )
                      else
                        _placeholder(isDark),
                      // Points badge on top right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF6B35,
                                ).withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info section
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? 'Gift Card',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFFF6B35),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pts pts',
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1B4F72,
                              ).withValues(alpha: isDark ? 0.8 : 1.0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Claim',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.card_giftcard_rounded,
        size: 52,
        color: isDark ? Colors.white24 : Colors.blueGrey.withValues(alpha: 0.3),
      ),
    );
  }
}
