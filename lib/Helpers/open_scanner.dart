import 'package:flutter/material.dart';
import 'package:msloyalty/Providers/point_provider.dart';
import 'package:msloyalty/Screens/qr_scanner_screen.dart';
import 'package:msloyalty/Screens/receipt_voucher_screen.dart';
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
        final txnData = await provider.addPoints(earnedPoints, spentAmount, qrCode: qrData);

        if (txnData != null && context.mounted) {
          // ၄။ Receipt Voucher သို့ တိုက်ရိုက်သွားမည်
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptVoucherScreen(data: txnData),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("အမှားအယွင်းရှိပါသည်: $e")));
        }
      }
    }
  }
}
