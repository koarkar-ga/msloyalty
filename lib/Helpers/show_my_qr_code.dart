import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

//import 'point_provider.dart'; // သင့် Provider ဖိုင်အမည်

class ShowMyQRScreen extends StatelessWidget {
  const ShowMyQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider မှတစ်ဆင့် User ID သို့မဟုတ် Member ID ကို ယူပါ
    final userId = "MOONSUN-MEMBER-001"; // ဥပမာ ID

    return Scaffold(
      appBar: AppBar(
        title: const Text("ကျွန်ုပ်၏ QR ကုဒ်", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B4F72), // MOONSUN Blue
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // အပေါ်ပိုင်း စာသား
            const Text(
              "ဆီဆိုင်ဝန်ထမ်းကို ဤ QR ပြသပါ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Point များ ရယူရန် သို့မဟုတ် လဲလှယ်ရန်",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // QR Code Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: QrImageView(
                data: userId, // QR ထဲတွင် သိမ်းဆည်းမည့် Data
                version: QrVersions.auto,
                size: 250.0,
                gapless: false,
                foregroundColor: const Color(0xFF1B4F72), // QR အရောင်
                // Logo အလယ်မှာ ထည့်ချင်ရင် အောက်က code ကို သုံးပါ
                embeddedImage: const NetworkImage(
                  'https://www.moonsungroup.com/wp-content/uploads/2024/11/moonsun_logo.png',
                ),
                embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(50, 50)),
              ),
            ),

            const SizedBox(height: 30),

            // Member ID ပြသခြင်း
            Text(
              "ID: $userId",
              style: const TextStyle(fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 50),

            // ပိတ်ရန် ခလုတ်
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828), // MOONSUN Red
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("ပိတ်ရန်", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
