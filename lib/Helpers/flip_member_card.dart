import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Screens/DynamicEarnQRScreen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class FlipMemberCard extends StatefulWidget {
  final String memberName;
  final String memberId;
  final String memberLabel;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color tagBg;
  final int currentPoints;
  final double progress;
  final String progressText;
  final String? tokenId; // QR token ID to show on back

  const FlipMemberCard({
    super.key,
    required this.memberName,
    required this.memberId,
    required this.memberLabel,
    required this.gradientColors,
    required this.accentColor,
    required this.tagBg,
    required this.currentPoints,
    required this.progress,
    required this.progressText,
    this.tokenId,
  });

  @override
  State<FlipMemberCard> createState() => _FlipMemberCardState();
}

class _FlipMemberCardState extends State<FlipMemberCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    // Flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutExpo),
    );

    // Floating animation (Defying gravity)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, -1),
        ).animate(
          CurvedAnimation(
            parent: _floatController,
            curve: Curves.easeInOutQuad,
          ),
        );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _flip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Floating 3D Perspective Card ──────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_flipAnimation, _floatAnimation]),
            builder: (context, child) {
              final flipValue = _flipAnimation.value;
              final floatOffset = _floatAnimation.value;
              final angle = flipValue * math.pi;
              final showFront = flipValue < 0.5;

              // Perspective Matrix
              final matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..translate(floatOffset.dx, floatOffset.dy) // Floating effect
                ..rotateX(-0.1) // Slight tilt towards viewer
                ..rotateY(angle); // Flip rotation

              return Transform(
                alignment: Alignment.center,
                transform: matrix,
                child: GestureDetector(
                  onTap: _flip,
                child: GestureDetector(
                  onTap: _flip,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        children: [
                          showFront ? _buildFront() : _buildBack(),
                          const SizedBox(height: 20),
                        ],
                      ),
                      // Glowing QR Button at Bottom Center
                      Positioned(
                        bottom: -10, // Adjusted to overlap the card properly
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DynamicEarnQRScreen(),
                              ),
                            ),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 165, 8, 8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromARGB(255, 255, 0, 0),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      136,
                                      0,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFront() {
    return _cardShell(
      child: Stack(
        clipBehavior: Clip.none, // Allow button to overflow shell
        children: [
          // Watermark Logo
          Positioned(
            right: 40,
            bottom: 80,
            child: Opacity(
              opacity: 0.1,
              child: Transform.scale(
                scale: 1.5,
                child: MoonSunLoading(isLoading: false),
              ),
            ),
          ),

          // Ambient Lighting Glare
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chip(),
                    const Text(
                      'MOONSUN ENERGY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Member Label Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.tagBg,
                    border: Border.all(color: Colors.white24, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.memberLabel.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'USER POINT BALANCE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.currentPoints.toDouble()),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      NumberFormat('#,###').format(val.round()),
                      style: const TextStyle(
                        color: Color(0xFFFFD700), // Gold Color
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Progress Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.progressText,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: widget.progress,
                              minHeight: 3,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: _cardShell(
        child: Stack(
          children: [
            // Watermark
            Positioned(
              left: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.08,
                child: Transform.scale(
                  scale: 2.0,
                  child: MoonSunLoading(isLoading: false),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Collect Point QR',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.tokenId != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'EARN|${widget.tokenId}',
                        version: QrVersions.auto,
                        size: 140,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0A192F),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0A192F),
                        ),
                      ),
                    )
                  else
                    MoonSunLoading(),
                  const SizedBox(height: 24),
                  const Text(
                    'VALID FOR 5 MINUTES',
                    style: TextStyle(
                      color: Color(0xFFFFD700), // Gold
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to hide QR',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 280, // Increased height to fix overflow (240 -> 280)
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0A192F), const Color(0xFF1B4F72)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 30),
            blurRadius: 40,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: const Color(0xFF1B4F72).withValues(alpha: 0.2),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child:
          child, // Removed ClipRRect to allow bottom button overflow if needed
    );
  }

  Widget _chip() {
    final label = widget.memberLabel.toUpperCase();
    IconData tierIcon = Icons.stars_rounded;
    Color iconColor = const Color(0xFFFFD700); // Default Gold

    if (label.contains('SILVER')) {
      tierIcon = Icons.workspace_premium;
      iconColor = const Color(0xFFC0C0C0); // Silver
    } else if (label.contains('GOLD')) {
      tierIcon = Icons.emoji_events_rounded;
      iconColor = const Color(0xFFFFD700); // Gold
    } else if (label.contains('PLATINUM')) {
      tierIcon = Icons.auto_awesome_rounded;
      iconColor = const Color(0xFFE5E4E2); // Platinum-ish
    } else if (label.contains('DIAMOND')) {
      tierIcon = Icons.diamond_rounded;
      iconColor = const Color(0xFFB9F2FF); // Diamond Blue
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(tierIcon, color: iconColor, size: 28),
    );
  }
}
