import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:msloyalty/Services/security_service.dart';

class IntroVideoScreen extends StatefulWidget {
  final String? videoUrl;
  const IntroVideoScreen({super.key, this.videoUrl});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Lock to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Hide status bar for immersive feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.setLooping(true);
          }
        });
    } else {
      _controller = VideoPlayerController.asset('assets/videos/intro.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.setLooping(true); // Loop while waiting for 5s timer
          }
        });
    }

    // 5 second timer to auto-navigate
    _timer = Timer(const Duration(seconds: 5), () {
      _navigateToNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    // Restore system UI and orientations
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _navigateToNext() {
    if (!mounted) return;
    _timer?.cancel();
    checkUserSession(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover, // Fullscreen portrait coverage
              child: _initialized
                  ? SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
          ),
          // Skip button
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: _navigateToNext,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
