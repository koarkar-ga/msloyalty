import 'package:flutter/material.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/qr_scanner_screen.dart';
import 'package:provider/provider.dart';

class OpenScanner {
  void scanner(BuildContext context) async {
    // ၁။ Scanner Screen ကို ဖွင့်ပြီး Result စောင့်မယ်
    final String? qrData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerScreen()),
    );

    if (qrData != null) {
      // ၂။ QR Data ကို စစ်ဆေးမယ် (ဥပမာ- ဆီဆိုင်ကထုတ်ပေးတဲ့ ကုဒ် ဟုတ်မဟုတ်)
      // ဒီနေရာမှာ Backend API နဲ့ စစ်တာမျိုး လုပ်ရပါမယ်

      // ဥပမာ - QR ထဲမှာ ကျသင့်ငွေ ၅၀,၀၀၀ ပါလာတယ်ဆိုပါစို့
      double spentAmount = 50000.0;
      int earnedPoints = (spentAmount / 1000).floor(); // ၁၀၀၀ ကျပ် ၁ point

      // ၃။ Provider ကနေတဆင့် Supabase မှာ Point သွားပေါင်းမယ်
      final provider = Provider.of<PointProvider>(context, listen: false);

      try {
        await provider.addPoints(earnedPoints, spentAmount);

        // ၄။ အောင်မြင်ကြောင်း UI ပြမယ်
        _showSuccessDialog(context, earnedPoints);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("အမှားအယွင်းရှိပါသည်: $e")));
      }
    }
  }

  void _showSuccessDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              "ဂုဏ်ယူပါသည်!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("သင် Point $points ရရှိပြီးပါပြီ။"),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B4F72),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text("ပိတ်ရန်", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
