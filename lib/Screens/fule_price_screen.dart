import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("ယနေ့ ဆီဈေးနှုန်းများ"),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Region Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1B4F72)),
                const SizedBox(width: 10),
                const Text("တိုင်းဒေသကြီး ရွေးရန်:", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                DropdownButton<String>(
                  value: selectedRegion,
                  items: ['Yangon', 'Mandalay', 'Naypyidaw', 'Shan State']
                      .map((String value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedRegion = val);
                      _fetchPrices();
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        _priceCard("Octane 92", currentPrices?['octane_92'], Colors.orange),
                        _priceCard("Octane 95", currentPrices?['octane_95'], Colors.red),
                        _priceCard("Diesel", currentPrices?['diesel'], Colors.blueGrey),
                        _priceCard("Premium Diesel", currentPrices?['premium_diesel'], Colors.blue),

                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            "နောက်ဆုံးပြင်ဆင်ချိန်: ${currentPrices != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(currentPrices!['updated_at'])) : '-'}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String title, int? price, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${price ?? '-'} MMK",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                const Text("Per Liter", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
