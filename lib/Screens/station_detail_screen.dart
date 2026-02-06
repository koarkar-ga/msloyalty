import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class StationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    // Database မှ image_url ကို ယူခြင်း
    final String? imageUrl = station['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(station['name']),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ဆိုင်ပုံ ပြသသည့် အပိုင်း ---
            Hero(
              tag: 'station-${station['id']}', // Hero Animation အတွက် tag
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover, // ပုံကို အကွက်အပြည့်ဖြည့်ရန်
                        )
                      : null,
                ),
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.local_gas_station, size: 80, color: Colors.grey)
                    : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          station['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          station['region'] ?? "Unknown",
                          style: const TextStyle(
                            color: Color(0xFF1B4F72),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  _infoRow(
                    Icons.location_on_rounded,
                    "လိပ်စာ",
                    station['address'] ?? "လိပ်စာမရှိပါ",
                  ),
                  const SizedBox(height: 20),
                  _infoRow(
                    Icons.phone_rounded,
                    "ဖုန်းနံပါတ်",
                    station['phone'] ?? "ဖုန်းနံပါတ်မရှိပါ",
                  ),

                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeCall(station['phone']),
                          icon: const Icon(Icons.call),
                          label: const Text("Call Now"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMap(station['map_url']),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text("Directions"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  // Info Row Widget
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1B4F72), size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 16, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ၁။ ဖုန်းခေါ်ဆိုရန် Function
Future<void> _makeCall(String? phoneNumber) async {
  if (phoneNumber == null || phoneNumber.isEmpty) return;

  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    debugPrint('ဖုန်းခေါ်ဆို၍ မရပါ');
  }
}

// ၂။ Google Maps ဖွင့်ရန် Function
Future<void> _openMap(String? mapUrl) async {
  if (mapUrl == null || mapUrl.isEmpty) return;

  final Uri url = Uri.parse(mapUrl);

  // အပြင် App (Google Maps) ဖြင့် ဖွင့်ရန်ကြိုးစားခြင်း
  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // Google Maps App ထဲ တိုက်ရိုက်သွားရန်
    );
  } else {
    debugPrint('မြေပုံဖွင့်၍ မရပါ');
  }
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF1B4F72)),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    ],
  );
}
