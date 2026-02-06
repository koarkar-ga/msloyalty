import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GiftCardScreen extends StatefulWidget {
  const GiftCardScreen({super.key});

  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<dynamic> giftCards = [];

  @override
  void initState() {
    super.initState();
    _fetchGiftCards();
  }

  Future<void> _fetchGiftCards() async {
    try {
      final data = await supabase.from('gift_cards').select().eq('is_available', true);
      setState(() {
        giftCards = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("လက်ဆောင်များ လဲလှယ်ရန်"),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ပုံပြသသည့်အပိုင်း
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: item['image_url'] != null
                    ? DecorationImage(image: NetworkImage(item['image_url']), fit: BoxFit.cover)
                    : null,
              ),
              child: item['image_url'] == null ? const Icon(Icons.card_giftcard, size: 50) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _redeemDialog(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: const Text("လဲလှယ်မည်"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _redeemDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("အတည်ပြုရန်"),
        content: Text(
          "${item['title']} ကို ${item['points_required']} points ဖြင့် လဲလှယ်မှာ သေချာပါသလား?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("မလုပ်တော့ပါ")),
          ElevatedButton(
            onPressed: () {
              /* လဲလှယ်မည့် Logic ဤနေရာတွင်ထည့်ပါ */
            },
            child: const Text("သေချာသည်"),
          ),
        ],
      ),
    );
  }
}
