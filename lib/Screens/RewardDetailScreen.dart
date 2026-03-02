import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/upload_photo.dart';

class RewardDetailPage extends StatefulWidget {
  final int rewardId;
  const RewardDetailPage({super.key, required this.rewardId});

  @override
  State<RewardDetailPage> createState() => _RewardDetailPageState();
}

class _RewardDetailPageState extends State<RewardDetailPage> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reward Detail',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.control_point, color: Colors.white),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: getRewardDetail(),
        builder: (context, snapShot) {
          if (snapShot.hasData) {
            final reward = snapShot.data;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Banner Section
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.8), Colors.black.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.local_gas_station,
                            size: 150,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              image: reward!['image_url'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(reward!['image_url']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: reward['image_url'] == null
                                ? const Icon(Icons.card_giftcard, size: 50, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reward!['title']}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white70,
                                ),
                                child: Text(
                                  '${reward!['description']}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry and Title
                const Text(
                  'Expire date: 31 Dec 2026, 00:00',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MOONSUN Energy',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 16),

                // Redemption section
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Redeem Reward',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${reward!['title']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Claim', style: TextStyle(fontSize: 16)),
                              onPressed: () async {
                                // show loading
                                // showDialog(
                                //   context: context,
                                //   barrierDismissible: false,
                                //   builder: (_) => const Center(child: CircularProgressIndicator()),
                                // );

                                try {
                                  final userId = supabase.auth.currentUser?.id;
                                  await supabase.from('redemption_history').insert({
                                    'reward_id': widget.rewardId,
                                    'user_id': userId,
                                    'points_spent': snapShot.data!['points_required'],
                                    'cpid': DateTime.now().millisecondsSinceEpoch,
                                    'created_at': DateTime.now().toIso8601String(),
                                  });

                                  Navigator.of(context).pop(); // close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Redemption requested. We will notify you when ready.',
                                      ),
                                    ),
                                  );
                                  // optionally refresh UI or navigate
                                  setState(() {});
                                } catch (e) {
                                  Navigator.of(context).pop(); // close loading
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('Failed to redeem: $e')));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Contact Bar
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone, color: Colors.black, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Need help? Call us at 09760255836',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description Section
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _buildTextList([
                  'ဆုလက်ဆောင် အတွက် သက်တမ်း ကုန်ဆုံးရက်မှာ 31 Dec 2026, 00:00',
                  'ဒီဆုလက်ဆောင် ကို နီးစပ်ရာ မွန်းဆန်း ဆီဆိုင်များတွင် ထုတ်ယူနိုင်ပါသည်။',
                  'လက်ဆောင်များဖြင့် ပါတ်သတ်ပြီး  အချက်အလတ်များကို ဆက်သွယ်ရန် 09760255836 သို့ ဖုန်းခေါ်ပါ။',
                  'ဆုလက်ဆောင်များကို အခြားသူများအား လွှဲပြောင်းရန် မရနိုင်ပါ။',
                  'MOONSUN Logo ပါ အမှတ်အသား ပါဝင်သော ဆုလက်ဆောင် ဖြစ်ပါသည်။',
                ]),
                const SizedBox(height: 24),

                // Terms and Conditions Section
                const Text(
                  'Terms and Conditions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                _buildMyanmarTextList([
                  'ဆုလက်ဆောင် အား Point ဖြင့် လဲလှယ်နိုင်ပါသည်။',
                  'ဆုလက်ဆောင် ၏ သက်တမ်းသည် (၁) နှစ် ဖြစ်ပါသည်။',
                  'ဆုလက်ဆောင် အား သက်ဆိုင်ရာ Brand များတွင်သာ အသုံးပြုနိုင်ပါသည်။',
                  'ဆုလက်ဆောင် လဲလှယ်ပြီးသော Point အား ပြန်လည်ပြီး ဆုဖြင့် လဲလှယ်၍ မရနိုင်ပါ။',
                ]),
                const SizedBox(height: 40),
              ],
            );
          } else {
            return const Center(child: Text("No Reward Details Available"));
          }
        },
      ),
    );
  }

  // English list helper
  Widget _buildTextList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item,
                style: const TextStyle(color: Colors.white38, fontSize: 15, height: 1.4),
              ),
            ),
          )
          .toList(),
    );
  }

  // Myanmar text helper
  Widget _buildMyanmarTextList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                item,
                style: const TextStyle(color: Colors.white38, fontSize: 14, height: 1.6),
              ),
            ),
          )
          .toList(),
    );
  }
}
