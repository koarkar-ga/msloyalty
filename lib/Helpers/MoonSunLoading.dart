import 'package:flutter/material.dart';

class MoonSunLoading extends StatefulWidget {
  @override
  _MoonSunLoadingState createState() => _MoonSunLoadingState();
}

class _MoonSunLoadingState extends State<MoonSunLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // တောက်လျှောက် လည်နေစေရန်

    // အပြာရောင်စက်ဝိုင်း ဘယ်ကနေ ညာကို ရွေ့မယ့် အကွာအဝေး
    _animation = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // ၁။ အောက်ခံ အနီရောင် စက်ဝိုင်း (Sun)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),

              // ၂။ အပေါ်က ဖြတ်သွားမယ့် အပြာရောင်စက်ဝိုင်း (Moon)
              Transform.translate(
                offset: Offset(_animation.value * 60, 0), // ဘေးတိုက်ရွေ့လျားမှု
                child: Container(
                  width: 90, // အနည်းငယ် သေးလိုက်လျှင် လခြမ်းပုံစံ ပိုပေါ်သည်
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ), // အပြာရောင် အထွေထွေ
                    color: Color(0xFF42A5F5), // Logo ထဲက အပြာရောင်
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ၃။ အလယ်က MOONSUN စာသား Banner (ရွေးချယ်နိုင်သည်)
              Container(
                margin: EdgeInsets.only(left: 60),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                color: Colors.white,
                child: Text(
                  "MOONSUN",
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
