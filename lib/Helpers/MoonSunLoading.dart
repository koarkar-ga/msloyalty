import 'package:flutter/material.dart';

class MoonSunLoading extends StatefulWidget {
  final bool isLoading;

  MoonSunLoading({Key? key, this.isLoading = true}) : super(key: key);

  @override
  _MoonSunLoadingState createState() => _MoonSunLoadingState();
}

class _MoonSunLoadingState extends State<MoonSunLoading> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _controller.forward();
    _textController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    widget.isLoading ? _textController.repeat() : _textController.stop();

    // အနီရောင်စက်ဝိုင်း ညာကနေပြီး ဘယ်ကို ရွေ့မယ့် အကွာအဝေး
    _animation = Tween<double>(
      begin: 1.5,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
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
              // ၁။ အောက်ခံ အပြာရောင် စက်ဝိုင်း (MOON) with shining overlay when animation completes
              Transform.scale(
                scale:
                    1.0 + (1.3 - _animation.value) * 0.12, // subtle scale based on moon animation
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 11, 14, 207),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),

                    // shining sweep across moon after main animation completes
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, _) {
                        if (!_controller.isCompleted) return SizedBox.shrink();
                        final double t = _textController.value;
                        // moving gradient center from left->right
                        return ClipOval(
                          child: IgnorePointer(
                            child: Container(
                              width: 100,
                              height: 100,
                              // shader mask paints a narrow white band that sweeps across
                              child: ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                    begin: Alignment(-1.5 + t * 3.0, 0),
                                    end: Alignment(-1.5 + t * 3.0 + 0.4, 0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.srcATop,
                                child: Container(color: Colors.white.withOpacity(0.0)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              //  reflection under moon when animation completes
              AnimatedBuilder(
                animation: _textController,
                builder: (context, _) {
                  if (!_controller.isCompleted) return SizedBox.shrink();
                  final double t = _textController.value;
                  final double opacity =
                      0.18 + 0.12 * (0.5 - ((t - 0.5).abs())) * 2; // gentle pulsing
                  return Transform.translate(
                    offset: Offset(0, 70),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 0.3),
                      child: Transform.scale(
                        scaleY: -1, // flip vertically to act as reflection
                        child: Container(
                          width: 88,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.35),
                                Colors.white.withOpacity(0.06),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ၂။ အပေါ်က ဖြတ်သွားမယ့် အနီရောင်စက်ဝိုင်း (Sun) with highlight sweep when complete
              Transform.translate(
                offset: Offset(_animation.value * 60, 0), // ဘေးတိုက်ရွေ့လျားမှု
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 98, // အနည်းငယ် သေးလိုက်လျင် လခြမ်းပုံစံ ပိုပေါ်သည်
                      height: 98,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2), // အပြာရောင် အထွေထွေ
                        color: Color.fromARGB(255, 163, 6, 6), // Logo ထဲက အပြာရောင်
                        shape: BoxShape.circle,
                      ),
                    ),

                    // subtle outer glow when completed
                    if (_controller.isCompleted && widget.isLoading)
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, _) {
                          final double pulse = 0.6 + 0.4 * (_textController.value);
                          return Container(
                            width: 110 * pulse,
                            height: 110 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.06),
                                  blurRadius: 12 * pulse,
                                  spreadRadius: 2 * pulse,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // ၃။ အလယ်က MOONSUN စာသား Banner (Fade + Zoom out)
              Builder(
                builder: (context) {
                  // t အရ opacity/scale အတွက် compute
                  final double t = ((_controller.value + 1) / 2.0).clamp(0.0, 1.0);
                  final double scale =
                      1.6 - 0.6 * t; // start bigger (zoomed in), then shrink to normal

                  // removed post-frame restart/reset which interrupted the repeating animation

                  return Transform.scale(
                    scale: scale,
                    child: _controller.isCompleted && widget.isLoading
                        ? Container(
                            margin: EdgeInsets.only(left: 56),
                            width: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color.lerp(Colors.transparent, Colors.white, t),
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
                                    animation: _textController,
                                    builder: (context, _) {
                                      return ShaderMask(
                                        shaderCallback: (rect) {
                                          final double t = _textController.value;
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
                                            color: Color.lerp(Colors.transparent, Colors.white, t),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            fontFamily: 'Times New Roman',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.only(left: 30),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color.lerp(Colors.transparent, Colors.white, t),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              "MOONSUN",
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                    // animation မပြီးသေးရင် ပုံတူတက်အတိုင်း Banner ပြမယ် (with box shadow)
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
