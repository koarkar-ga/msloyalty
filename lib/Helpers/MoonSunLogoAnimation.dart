import 'dart:math' as math;
import 'package:flutter/material.dart';

class MoonSunLoadingScreen extends StatefulWidget {
  const MoonSunLoadingScreen({super.key});

  @override
  State<MoonSunLoadingScreen> createState() => _MoonSunLoadingScreenState();
}

class _MoonSunLoadingScreenState extends State<MoonSunLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // For Ring Rotation
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // For Text Pulsing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A25), // Deep dark blue background
      body: MoonSunLogoLoadingAnimator(controller: _controller, pulseController: _pulseController),
    );
  }
}

class MoonSunLogoLoadingAnimator extends StatelessWidget {
  const MoonSunLogoLoadingAnimator({
    super.key,
    required AnimationController controller,
    required AnimationController pulseController,
  }) : _controller = controller,
       _pulseController = pulseController;

  final AnimationController _controller;
  final AnimationController _pulseController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Background Stars/Particles (Static for performance, can be animated)
        const Positioned.fill(child: StarField()),

        // 2. Rotating Segmented Ring
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(size: const Size(300, 300), painter: SegmentedRingPainter()),
            );
          },
        ),

        // 3. Central Logo & Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for the Logo (Using Icon/Shapes to mimic the image)
            Image.asset('assets/images/moonsun_logo.png', width: 150),
            const SizedBox(height: 20),
            // Brand Name
            const Text(
              "MOONSUN",
              style: TextStyle(
                color: Color(0xFFE0BB68), // Gold/Yellow tint
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              "Energy",
              style: TextStyle(color: Color(0xFFE0BB68), fontSize: 16, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 20),
            // Loading Text (Pulsing)
            FadeTransition(
              opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_pulseController),
              child: const Text(
                "LOADING...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- Custom Painters & Widgets below ---

// 1. The Ring Painter (Red and Blue Segments)
class SegmentedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt; // Flat ends for segments

    // Define segments: Total 20 segments
    const int segmentCount = 20;
    const double gap = 0.08; // Gap size in radians
    const double segmentAngle = (2 * math.pi / segmentCount) - gap;

    for (int i = 0; i < segmentCount; i++) {
      // Determine color based on pattern
      // Pattern in image looks like: 2 Blue, 1 Red, etc. mixed.
      // Let's create a pattern: Red, Blue, Blue, Blue, Red, Blue...
      if (i % 5 == 0 || i % 5 == 1) {
        paint.color = const Color(0xFFFF3B3B); // Red
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); // Glow
      } else {
        paint.color = const Color(0xFF89CFF0); // Light Blue
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      }

      final double startAngle = i * (segmentAngle + gap);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Simple Star/Particle Field Background
class StarField extends StatelessWidget {
  const StarField({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: StarPainter());
  }
}

class StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    final random = math.Random(42); // Fixed seed for static stars

    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double radius = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// 3. Recreating the MoonSun Logo (Simplified)
class MoonSunLogoWidget extends StatelessWidget {
  const MoonSunLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Red Circle
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
          ),
          // Blue Crescent (Moon) - Simulated by overlapping
          Positioned(
            left: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                // This mimics the moon shape cutting into the red circle
                // In a real app, use an SVG asset or Image.asset
                color: Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF42A5F5), // Blue Moon Color
                    offset: Offset(-15, 0),
                    spreadRadius: -10,
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          // Logo Text Overlay
          const Positioned(
            child: Text(
              "MOONSUN",
              style: TextStyle(
                fontSize: 8,
                color: Colors.white,
                backgroundColor: Color(0xFF050A25), // Just to make it readable in this hacky logo
              ),
            ),
          ),
        ],
      ),
    );
  }
}
