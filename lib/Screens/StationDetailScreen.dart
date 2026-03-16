import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class StationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> station;
  const StationDetailScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = station['image_url'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subColor = Theme.of(context).textTheme.bodyMedium?.color;
    final fgColor = Theme.of(context).appBarTheme.foregroundColor;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(station['name'], style: TextStyle(fontSize: 16, color: fgColor)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: fgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: fgColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Station Image
            Hero(
              tag: 'station-${station['id']}',
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2D45) : const Color(0xFFE8F4FD),
                  image: imageUrl != null && imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_gas_station,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.blueGrey.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text(
                            'No Image',
                            style: TextStyle(color: subColor, fontSize: 12),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Region badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          station['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (station['region'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B4F72).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1B4F72).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            station['region'],
                            style: const TextStyle(
                              color: Color(0xFF1B4F72),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info Cards
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.location_on_rounded,
                          label: 'လိပ်စာ',
                          value: station['address'] ?? 'လိပ်စာမရှိပါ',
                          textColor: textColor,
                          subColor: subColor,
                          isLast: false,
                        ),
                        Divider(height: 1, indent: 56, color: isDark ? Colors.white12 : Colors.black12),
                        _infoTile(
                          icon: Icons.phone_rounded,
                          label: 'ဖုန်းနံပါတ်',
                          value: station['phone'] ?? 'ဖုန်းနံပါတ်မရှိပါ',
                          textColor: textColor,
                          subColor: subColor,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeCall(station['phone']),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMap(station['map_url']),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? textColor,
    Color? subColor,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4F72).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1B4F72), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: subColor, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _makeCall(String? phoneNumber) async {
  if (phoneNumber == null || phoneNumber.isEmpty) return;
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
  if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
}

Future<void> _openMap(String? mapUrl) async {
  if (mapUrl == null || mapUrl.isEmpty) return;
  final Uri url = Uri.parse(mapUrl);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
