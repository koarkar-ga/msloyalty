import 'package:flutter/material.dart';

class MoonSunLoading extends StatefulWidget {
  @override
  _MoonSunLoadingState createState() => _MoonSunLoadingState();
}

class _MoonSunLoadingState extends State<MoonSunLoading> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _moonController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _moonController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _moonController.forward();

    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _controller.forward();

    // အပြာရောင်စက်ဝိုင်း ဘယ်ကနေ ညာကို ရွေ့မယ့် အကွာအဝေး
    _animation = Tween<double>(
      begin: -1.5,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _moonController, curve: Curves.easeInOut));
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
                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),

              // ၂။ အပေါ်က ဖြတ်သွားမယ့် အပြာရောင်စက်ဝိုင်း (Moon)
              Transform.translate(
                offset: Offset(_animation.value * 60, 0), // ဘေးတိုက်ရွေ့လျားမှု
                child: Container(
                  width: 90, // အနည်းငယ် သေးလိုက်လျင် လခြမ်းပုံစံ ပိုပေါ်သည်
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4), // အပြာရောင် အထွေထွေ
                    color: Color(0xFF42A5F5), // Logo ထဲက အပြာရောင်
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // ၃။ အလယ်က MOONSUN စာသား Banner (Fade + Zoom out)
              Builder(
                builder: (context) {
                  // t အရ opacity/scale အတွက် compute
                  final double t = ((_animation.value + 1.5) / 2.0).clamp(0.0, 1.0);
                  final double scale =
                      1.6 - 0.6 * t; // start bigger (zoomed in), then shrink to normal

                  // animation ပြီးသွားပြီလား စစ်ဆေး၊ ပြီးသွားရင် repeating loading ဖော်ပြရန် controller.repeat() ခေါ်မယ်
                  final bool completed = _controller.status == AnimationStatus.completed;

                  // ပြီးသွားချိန်မှာ controller.repeat() ကို build loop ထဲမှာ တိုက်ရိုက်ခေါ်မရလိုပါက
                  // post frame callback ထဲကနေ တစ်ကြိမ်သာ ခေါ်စေမယ်
                  if (completed && !_controller.isAnimating) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _controller.status == AnimationStatus.completed) {
                        _controller.repeat();
                      }
                    });
                  }

                  return Transform.scale(
                    scale: scale,
                    child: completed
                        // Animation complete ဖြစ်သွားရင် BoxShadow ပျောက်သွားပြီး
                        // MOONSUN ပိုင်းကို Linear loading ပုံစံသို့ ပြောင်းမယ် (indeterminate)
                        ? Container(
                            margin: EdgeInsets.only(left: 70),
                            width: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.transparent,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) {
                                      return ShaderMask(
                                        shaderCallback: (rect) {
                                          final double t = _controller.value;
                                          // moving gradient window
                                          return LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.blue.shade900,
                                              Colors.white,
                                              Colors.blue.shade900,
                                            ],
                                            stops: [
                                              (t - 0.3).clamp(0.0, 1.0),
                                              t.clamp(0.0, 1.0),
                                              (t + 0.3).clamp(0.0, 1.0),
                                            ],
                                          ).createShader(rect);
                                        },
                                        blendMode: BlendMode.srcIn,
                                        child: Text(
                                          "MOONSUN",
                                          // keep local text style here (outer style in your original code should be removed
                                          // if you paste this replacement as-is)
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        // animation မပြီးသေးရင် ပုံတူတက်အတိုင်း Banner ပြမယ် (with box shadow)
                        : Opacity(
                            opacity: t,
                            child: Container(
                              margin: EdgeInsets.only(left: 70),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.transparent,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "MOONSUN",
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
