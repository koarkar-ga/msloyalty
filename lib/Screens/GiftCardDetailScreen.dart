import 'package:flutter/material.dart';

class Giftcarddetailscreen extends StatefulWidget {
  const Giftcarddetailscreen({super.key});

  @override
  State<Giftcarddetailscreen> createState() => _GiftcarddetailscreenState();
}

class _GiftcarddetailscreenState extends State<Giftcarddetailscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("GiftCardDetailScreen")));
  }
}
