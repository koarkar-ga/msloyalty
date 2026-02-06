import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // ကင်မရာကို ထိန်းချုပ်ရန် Controller
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR စကင်ဖတ်ပါ", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B4F72), // MOONSUN Royal Blue
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ကင်မရာ မြင်ကွင်း
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? "---";
                // QR ဖတ်မိလျှင် Data ကိုယူ၍ ရှေ့စာမျက်နှာသို့ ပြန်သွားမည်
                Navigator.pop(context, code);
              }
            },
          ),
          // စကင်ဖတ်ရန် ဘောင်ကွက် (Overlay)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
