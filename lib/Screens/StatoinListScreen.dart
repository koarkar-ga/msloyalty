import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/StationDetailScreen.dart';
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
        final region = (s['region'] ?? '')
            .toString()
            .toLowerCase(); // Region ကိုပါ စစ်မည်
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final fgColor = Theme.of(context).appBarTheme.foregroundColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("ဆိုင်များ ရှာဖွေရန်"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: fgColor,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios, color: fgColor, size: 20),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: _filterStations,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "ဆိုင်အမည် သို့မဟုတ် မြို့နယ်ဖြင့်ရှာပါ",
                hintStyle: TextStyle(color: subColor, fontSize: 12),
                prefixIcon: Icon(Icons.search, color: subColor),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(child: MoonSunLoading())
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
                              builder: (context) =>
                                  StationDetailScreen(station: station),
                            ),
                          );
                        },
                        child: Card(
                          color: cardColor,
                          elevation: isDark ? 4 : 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFF1B4F72,
                              ).withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.local_gas_station,
                                color: Color(0xFF1B4F72),
                                size: 20,
                              ),
                            ),
                            title: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station['name'],
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (station['region'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1B4F72,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      station['region'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF1B4F72),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  station['address'],
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 12,
                                      color: subColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      station['phone'] ?? '-',
                                      style: TextStyle(
                                        color: subColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: subColor,
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
