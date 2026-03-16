import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Screens/FuelTransactionDetailScreen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final locale = settings.locale;
        final fgColor = Theme.of(context).appBarTheme.foregroundColor;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                'history_title'.tr(locale),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: fgColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: fgColor, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: TabBar(
                labelColor: fgColor,
                unselectedLabelColor: fgColor?.withValues(alpha: 0.6),
                indicatorColor: const Color(0xFF1B4F72),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: [
                  Tab(text: 'tab_fuel'.tr(locale)),
                  Tab(text: 'tab_redeem'.tr(locale)),
                ],
              ),
            ),
            body: const TabBarView(
              children: [FuelHistoryTab(), RedeemHistoryTab()],
            ),
          ),
        );
      },
    );
  }
}

// ၁။ ဆီဖြည့်မှတ်တမ်း Tab
class FuelHistoryTab extends StatelessWidget {
  const FuelHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return StreamBuilder(
      stream: supabase
          .from('v_fuel_transactions_with_stations')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(30),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: MoonSunLoading());
        final data = snapshot.data!;

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_gas_station_outlined,
                  size: 56,
                  color: subColor,
                ),
                const SizedBox(height: 12),
                Text('No fuel history yet', style: TextStyle(color: subColor)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final tx = data[index];
            // null-safe field access
            final stationName = tx['station_name']?.toString() ?? '-';
            final fuelType = tx['fuel_type']?.toString() ?? '-';
            final amountMmk = tx['amount_mmk']?.toString() ?? '0';
            final pointsEarned = tx['points_earned']?.toString() ?? '0';
            final createdAt = tx['created_at'] != null
                ? DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.parse(tx['created_at']))
                : '-';

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FuelTransactionDetailScreen(data: tx),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.local_gas_station,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    stationName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '$fuelType · $createdAt',
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountMmk Ks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '+$pointsEarned pts',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ၂။ လက်ဆောင်လဲလှယ်မှု Tab
class RedeemHistoryTab extends StatelessWidget {
  const RedeemHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;

    return StreamBuilder(
      stream: supabase
          .from('redemption_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: MoonSunLoading());
        final data = snapshot.data!;

        if (data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard_outlined, size: 56, color: subColor),
                const SizedBox(height: 12),
                Text('No redemptions yet', style: TextStyle(color: subColor)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: data.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final rd = data[index];
            final pointsSpent = rd['points_spent']?.toString() ?? '0';
            final createdAt = rd['created_at'] != null
                ? DateFormat(
                    'dd MMM yyyy',
                  ).format(DateTime.parse(rd['created_at']))
                : '-';

            return FutureBuilder<Map<String, dynamic>>(
              future: supabase
                  .from('gift_cards')
                  .select('title')
                  .eq('id', rd['reward_id'])
                  .single(),
              builder: (context, snap) {
                final title = snap.data?['title']?.toString() ?? 'Reward';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      createdAt,
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                    trailing: Text(
                      '-$pointsSpent pts',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
