import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:msloyalty/Providers/settings_provider.dart';

class FuelPriceScreen extends StatefulWidget {
  const FuelPriceScreen({super.key});

  @override
  State<FuelPriceScreen> createState() => _FuelPriceScreenState();
}

class _FuelPriceScreenState extends State<FuelPriceScreen> {
  final supabase = Supabase.instance.client;
  String selectedRegion = 'Yangon';
  Map<String, dynamic>? currentPrices;
  bool isLoading = true;

  // Region → DB value mapping (always EN for query)
  static const List<Map<String, String>> _regions = [
    {'en': 'Yangon', 'mm': 'ရန်ကုန်'},
    {'en': 'Mandalay', 'mm': 'မန္တလေး'},
    {'en': 'Naypyidaw', 'mm': 'နေပြည်တော်'},
    {'en': 'Shan State', 'mm': 'ရှမ်းပြည်နယ်'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('fuel_prices')
          .select()
          .eq('region', selectedRegion)
          .single();
      setState(() {
        currentPrices = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("FuelPrice Error: $e");
      setState(() => isLoading = false);
    }
  }

  String _regionDisplayName(String enValue, String locale) {
    final match = _regions.firstWhere(
      (r) => r['en'] == enValue,
      orElse: () => {'en': enValue, 'mm': enValue},
    );
    return locale == 'mm' ? (match['mm'] ?? enValue) : enValue;
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
        final selectorBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final selectorBorder = isDark ? Colors.white12 : Colors.black12;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'fuel_price_title'.tr(locale),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: fgColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: fgColor),
                onPressed: _fetchPrices,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Region Selector ──────────────────────────────────
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selectorBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selectorBorder),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4F72).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF1B4F72),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'region_select'.tr(locale),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRegion,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: subColor,
                        ),
                        dropdownColor: selectorBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        items: _regions.map((r) {
                          final enVal = r['en']!;
                          return DropdownMenuItem(
                            value: enVal,
                            child: Text(_regionDisplayName(enVal, locale)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedRegion = val);
                            _fetchPrices();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Price List ───────────────────────────────────────
              Expanded(
                child: isLoading
                    ? Center(child: MoonSunLoading())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView(
                          children: [
                            _priceCard(
                              context,
                              title: 'Octane 92',
                              price: currentPrices?['octane_92'],
                              color: Colors.orange,
                              icon: Icons.local_gas_station,
                              locale: locale,
                              isDark: isDark,
                              textColor: textColor,
                            ),
                            _priceCard(
                              context,
                              title: 'Octane 95',
                              price: currentPrices?['octane_95'],
                              color: Colors.red.shade600,
                              icon: Icons.local_gas_station,
                              locale: locale,
                              isDark: isDark,
                              textColor: textColor,
                            ),
                            _priceCard(
                              context,
                              title: 'Diesel',
                              price: currentPrices?['diesel'],
                              color: Colors.blueGrey,
                              icon: Icons.oil_barrel_outlined,
                              locale: locale,
                              isDark: isDark,
                              textColor: textColor,
                            ),
                            _priceCard(
                              context,
                              title: 'Premium Diesel',
                              price: currentPrices?['premium_diesel'],
                              color: const Color(0xFF1B4F72),
                              icon: Icons.oil_barrel,
                              locale: locale,
                              isDark: isDark,
                              textColor: textColor,
                            ),
                            const SizedBox(height: 16),
                            if (currentPrices != null)
                              Center(
                                child: Text(
                                  '${'updated_at'.tr(locale)}: ${DateFormat('dd MMM yyyy  HH:mm').format(DateTime.parse(currentPrices!['updated_at']))}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _priceCard(
    BuildContext context, {
    required String title,
    required int? price,
    required Color color,
    required IconData icon,
    required String locale,
    required bool isDark,
    required Color? textColor,
  }) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price != null ? NumberFormat('#,###').format(price) : '---',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    'MMK / ${'per_liter'.tr(locale)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor?.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
