import 'dart:async';
import 'package:flutter/material.dart';
import 'package:msloyalty/Helpers/MoonSunLoading.dart';
import 'package:msloyalty/Helpers/update_dialog.dart';
import 'package:msloyalty/Services/version_service.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Screens/pin_verify_page.dart';
import 'package:msloyalty/Services/ad_service.dart';
import 'package:msloyalty/Screens/splash_ad_screen.dart';
import 'package:msloyalty/Screens/intro_video_screen.dart';
import 'package:msloyalty/Services/security_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _startInitialization();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _startInitialization() async {
    // Keep it just long enough for the premium feel
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Check for updates
    final updateInfo = await VersionService.checkUpdate();
    if (updateInfo['available'] == true) {
      final latestVersion = updateInfo['version'] as AppVersion;
      if (mounted) {
        await UpdateDialog.show(context, latestVersion);

        // If it's mandatory, we stop here.
        if (latestVersion.isMandatory) return;

        // After closing the non-mandatory dialog, proceed to session check
        if (mounted) {
          _handlePostInitialization();
        }
      }
    } else {
      if (mounted) {
        _handlePostInitialization();
      }
    }
  }

  Future<void> _handlePostInitialization() async {
    final ad = await AdService.getActiveSplashAd();
    
    if (ad != null && mounted) {
      // Show Ad screen and wait for it to be dismissed
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SplashAdScreen(
            imageUrl: ad['image_url'],
            duration: ad['duration'],
          ),
        ),
      );
      
      // Once Ad screen is popped, proceed to app
      if (mounted) _proceedToApp();
    } else {
      _proceedToApp();
    }
  }

  Future<void> _proceedToApp() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    // Check PIN first if enabled
    bool pinPassed = true;
    if (settings.pinLockEnabled) {
      final verified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PinVerifyPage(isForUnlock: true),
        ),
      );
      pinPassed = (verified == true);
    }

    if (!pinPassed || !mounted) return;

    // Check Intro Video status
    final introVideo = await AdService.getActiveIntroVideo();
    
    if (introVideo == null || !introVideo['is_active']) {
      // If intro video is disabled, go straight to session check
      if (mounted) {
        await checkUserSession(context);
      }
    } else {
      // If intro video is active, show it (managed or default)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IntroVideoScreen(
              videoUrl: introVideo['video_url'],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Deep Space Background Gradient ────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A192F), Color(0xFF132B4F)],
              ),
            ),
          ),

          // ── Subtle Animated Depth Orbs ────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B4F72).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Immersive Logo with Shadow ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Hero(
                      tag: 'app_logo',
                      child: MoonSunLoading(isLoading: false),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Minimalist Loading indicator ──
                  SizedBox(
                    width: 40,
                    height: 2,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFFFD700).withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
