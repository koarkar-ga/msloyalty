import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/dynamic_qr_redemtion.dart';
import 'package:msloyalty/Screens/RewardDetailScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  // Supabase instance ကို ရယူခြင်း
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<dynamic> giftCards = [];

  @override
  void initState() {
    super.initState();
    _fetchGiftCards();
  }

  /// လက်ဆောင်ကတ်များကို database မှ ဆွဲယူခြင်း
  Future<void> _fetchGiftCards() async {
    try {
      final data = await supabase.from('gift_cards').select().eq('is_available', true);

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

  /// Point လဲလှယ်ခြင်း လုပ်ငန်းစဉ် (Database Function နှင့် ချိတ်ဆက်မှု)
  Future<void> _processRedemption(dynamic item) async {
    // လက်ရှိ Login ဝင်ထားသော User ID ကို ယူခြင်း
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Loading ပြရန်
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Database မှာရှိတဲ့ PostgreSQL Function (RPC) ကို လှမ်းခေါ်ခြင်း
      // Parameters များသည် Function ထဲက နာမည်များနှင့် ကိုက်ညီရပါမည်
      await supabase.rpc(
        'process_reward_redemption',
        params: {
          'target_user_id': userId,
          'target_reward_id': item['id'],
          'required_points': item['points_required'],
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // Loading ပိတ်ရန်
      Navigator.pop(context); // Dialog ပိတ်ရန်

      // အောင်မြင်ကြောင်း Alert ပြရန်
      _showMessage("အောင်မြင်ပါသည်", "လက်ဆောင်လဲလှယ်မှု ပြီးမြောက်သွားပါပြီ။", Colors.green);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Loading ပိတ်ရန်

      // Point မလောက်လျှင် သို့မဟုတ် အမှားတက်လျှင် ပြရန်
      String errorMsg = e.toString().contains('Insufficient points')
          ? "Point မလုံလောက်ပါသဖြင့် လဲလှယ်၍ မရနိုင်ပါ။"
          : "စနစ်ချို့ယွင်းမှု ဖြစ်ပေါ်နေပါသည်။ ခဏနေမှ ပြန်ကြိုးစားပါ။";

      _showMessage("အမှားအယွင်း", errorMsg, Colors.red);
    }
  }

  void _showMessage(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: color)),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        title: const Text("လက်ဆောင်များ လဲလှယ်ရန်"),
        backgroundColor: Colors.black26,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: MoonSunLoading())
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: giftCards.length,
              itemBuilder: (context, index) {
                final item = giftCards[index];
                return _buildGiftCard(item);
              },
            ),
    );
  }

  Widget _buildGiftCard(dynamic item) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => RewardDetailPage(rewardId: item['id']))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  image: item['image_url'] != null
                      ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                      : null,
                ),
                child: item['image_url'] == null
                    ? const Icon(Icons.card_giftcard, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title']}' ?? 'Gift Card',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.orange, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        "${item['points_required']} Points",
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => _redeemDialog(item),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: const Color(0xFF1B4F72),
                  //       foregroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(8),
                  //       ),
                  //       padding: EdgeInsets.zero,
                  //     ),
                  //     child: const Text("လဲလှယ်မည်"),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redeemDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("အတည်ပြုရန်"),
        content: Text(
          "${item['title']} ကို ${item['points_required']} points ဖြင့် လဲလှယ်မှာ သေချာပါသလား?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("မလုပ်တော့ပါ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => DynamicQRRedemption(item: item))),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F72)),
            child: const Text("သေချာသည်", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
