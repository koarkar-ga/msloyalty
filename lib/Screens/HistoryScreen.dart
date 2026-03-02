import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/FuelTransactionDetailScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // ရက်စွဲပုံစံပြင်ရန်

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black12,
        appBar: AppBar(
          title: const Text("မှတ်တမ်းများ"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            // စာသားအရောင်ကို အဖြူရောင်သတ်မှတ်ခြင်း
            labelColor: Colors.white,
            unselectedLabelColor:
                Colors.white70, // မရွေးချယ်ထားသော Tab ကို အဖြူရောင် မှိန်မှိန်လေးပြရန်
            indicatorColor: Colors.white, // အောက်ခြေလိုင်းကို အဖြူရောင်ထားရန်
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "ဆီဖြည့်မှတ်တမ်း"),
              Tab(text: "လက်ဆောင်လဲလှယ်မှု"),
            ],
          ),
        ),
        body: const TabBarView(children: [FuelHistoryTab(), RedeemHistoryTab()]),
      ),
    );
  }
}

// ၁။ ဆီဖြည့်မှတ်တမ်း Tab
class FuelHistoryTab extends StatelessWidget {
  const FuelHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder(
      stream: supabase
          .from('fuel_transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: MoonSunLoading());
        final data = snapshot.data!;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final tx = data[index];
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FuelTransactionDetailScreen(data: tx)),
              ),
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: ListTile(
                  leading: const Icon(Icons.local_gas_station, color: Colors.blue),
                  title: Text(
                    tx['station_name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${tx['fuel_type']} | ${DateFormat('dd MMM yyyy').format(DateTime.parse(tx['created_at']))}",
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${tx['amount_mmk']} Ks",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "+${tx['points_earned']} Pts",
                        style: const TextStyle(color: Colors.green, fontSize: 12),
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

    return StreamBuilder(
      stream: supabase
          .from('redemption_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', supabase.auth.currentUser!.id)
          .order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: MoonSunLoading());
        final data = snapshot.data!;

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final rd = data[index];
            final rewardQuery = supabase
                .from('gift_cards')
                .select('title')
                .eq('id', rd['reward_id'])
                .single();
            return FutureBuilder(
              future: rewardQuery,
              builder: (context, snapshot2) {
                String titleText = 'Reward';
                if (snapshot2.hasData) {
                  final res = snapshot2.data;
                  if (res is Map && res!['title'] != null) {
                    titleText = res['title'].toString();
                  } else if (res is Map &&
                      res!.containsKey('data') &&
                      res['data'] is Map &&
                      res['data']['title'] != null) {
                    // handle wrappers that place result under 'data'
                    titleText = res['data']['title'].toString();
                  } else {
                    titleText = snapshot2.data.toString();
                  }
                } else if (snapshot2.hasError) {
                  titleText = 'Unknown';
                }
                return ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.white),
                  title: Text(titleText, style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(DateTime.parse(rd['created_at'])),
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    "-${rd['points_spent']} Pts",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
