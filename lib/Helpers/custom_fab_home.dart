import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/dynamic_qr_reward_screen.dart';
import 'package:msloyalty/Helpers/open_scanner.dart';
import 'package:msloyalty/Helpers/show_my_qr_code.dart';

class CustomScannerFAB extends StatelessWidget {
  const CustomScannerFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFC62828), // Premium Red
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
      onPressed: () {
        // FAB ကို နှိပ်လိုက်လျှင် Popup (Bottom Sheet) ပြသခြင်း
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          builder: (context) => const ActionMenuSheet(),
        );
      },
    );
  }
}

class ActionMenuSheet extends StatelessWidget {
  const ActionMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Content ရှိသလောက်သာ အမြင့်ယူရန်
        children: [
          const Text(
            "ကျေးဇူးပြု၍ တစ်ခုခုရွေးချယ်ပါ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4F72)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Option 1: Scan Me (ကိုယ့် QR ကို ဝန်ထမ်းအားပြရန်)
              _buildMenuOption(
                context,
                icon: Icons.qr_code_2_rounded,
                label: "Scan Me",
                color: const Color(0xFF1B4F72),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DynamicQRRewardScreen()),
                ),
              ),
              // Option 2: Scan QR (အခြား QR များ ဖတ်ရန်)
              _buildMenuOption(
                context,
                icon: Icons.center_focus_weak_rounded,
                label: "Scan QR",
                color: const Color(0xFFC62828),
                onTap: () => OpenScanner().scanner(context),
              ),
            ],
          ),
          const SizedBox(height: 16), // Bottom padding အတွက်
        ],
      ),
    );
  }

  // Menu တစ်ခုချင်းစီအတွက် Helper Widget
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  static VoidCallback? showActionMenu(BuildContext context) {}
}
