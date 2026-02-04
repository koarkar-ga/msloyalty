import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final String? assetPath; // optional logo image

  const AnimatedLogo({super.key, this.size = 140, this.assetPath});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _glow = Tween<double>(
      begin: 6,
      end: 18,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: _glow.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _buildLogo(),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    if (widget.assetPath != null) {
      return Image.asset(widget.assetPath!, fit: BoxFit.contain);
    }

    // Fallback icon logo (fuel + loyalty vibe)
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A1A2F)),
      child: const Center(child: Icon(Icons.local_gas_station, color: Colors.amber, size: 80)),
    );
  }
}
