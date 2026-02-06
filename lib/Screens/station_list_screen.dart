import 'package:flutter/material.dart';
import 'package:msloyalty/Screens/station_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StationListScreen extends StatefulWidget {
  const StationListScreen({super.key});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> stations = [];
  List<Map<String, dynamic>> filteredStations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  // ၁။ Database မှ ဆိုင်စာရင်း ဆွဲယူခြင်း
  Future<void> _fetchStations() async {
    try {
      final data = await supabase.from('stations').select().order('name');
      setState(() {
        stations = List<Map<String, dynamic>>.from(data);
        filteredStations = stations;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching stations: $e");
    }
  }

  // ၂။ ဆိုင်ရှာဖွေခြင်း Logicvoid _filterStations(String query) {
  void _filterStations(String query) {
    setState(() {
      filteredStations = stations.where((s) {
        final name = s['name'].toString().toLowerCase();
        final address = s['address'].toString().toLowerCase();
        final region = (s['region'] ?? '').toString().toLowerCase(); // Region ကိုပါ စစ်မည်
        final searchLower = query.toLowerCase();

        return name.contains(searchLower) ||
            address.contains(searchLower) ||
            region.contains(searchLower);
      }).toList();
    });
  }

  // ၃။ ဖုန်းခေါ်ဆိုခြင်း နှင့် Maps ဖွင့်ခြင်း
  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ဆိုင်များ ရှာဖွေရန်"),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterStations,
              decoration: InputDecoration(
                hintText: "ဆိုင်အမည် သို့မဟုတ် မြို့နယ်ဖြင့်ရှာပါ",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStations.isEmpty
                ? const Center(child: Text("ဆိုင်စာရင်း မရှိသေးပါ"))
                : ListView.builder(
                    itemCount: filteredStations.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final station = filteredStations[index];
                      return GestureDetector(
                        onTap: () {
                          // Card ကို နှိပ်လိုက်လျှင် Details Screen သို့ သွားမည်
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StationDetailScreen(station: station),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),

                            title: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (station['region'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      station['region'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF1B4F72),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(station['address']),
                                const SizedBox(height: 5),
                                Text(
                                  "ဖုန်း: ${station['phone'] ?? '-'}",
                                  style: const TextStyle(color: Colors.blueGrey),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.green),
                                  onPressed: () => _launchURL("tel:${station['phone']}"),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.directions, color: Colors.blue),
                                  onPressed: () =>
                                      _launchURL(station['map_url'] ?? "https://maps.google.com"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
