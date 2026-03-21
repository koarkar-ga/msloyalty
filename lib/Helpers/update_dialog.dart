import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:msloyalty/Services/version_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Services/download_service.dart';
import 'dart:io';

class UpdateDialog extends StatefulWidget {
  final AppVersion version;

  const UpdateDialog({super.key, required this.version});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();

  static Future<void> show(BuildContext context, AppVersion version) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: !version.isMandatory,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return WillPopScope(
          onWillPop: () async => !version.isMandatory,
          child: UpdateDialog(version: version),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12 * anim1.value,
            sigmaY: 12 * anim1.value,
          ),
          child: child,
        );
      },
    );
  }
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  void _startDownload() async {
    if (Platform.isIOS || Platform.isWindows) {
      _launchLegacyURL();
      return;
    }

    setState(() {
      _isDownloading = true;
      _error = null;
    });

    await DownloadService.downloadAndInstall(
      url: widget.version.androidUrl ?? '',
      fileName: 'moonsun_update_${widget.version.buildNumber}.apk',
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _error = err;
          });
        }
      },
      onComplete: () {
        if (mounted && !widget.version.isMandatory) {
          Navigator.pop(context);
        }
      },
    );
  }

  void _launchLegacyURL() async {
    String? url;
    if (Platform.isAndroid) {
      url = widget.version.androidUrl;
    } else if (Platform.isIOS) {
      url = widget.version.iosUrl;
    } else if (Platform.isWindows) {
      url = widget.version.windowsUrl;
    }

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final locale = settings.locale;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Center(
            child: Container(
              width: 340,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A192F).withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header Gradient Section ────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.shade800,
                            const Color(0xFFE53935),
                            const Color(0xFFFFB300),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(seconds: 2),
                            tween: Tween(begin: 0, end: 1),
                            curve: Curves.easeInOut,
                            builder: (context, val, child) {
                              return Transform.translate(
                                offset: Offset(0, -5 * (val - 0.5).abs() * 2),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isDownloading
                                    ? Icons.downloading_rounded
                                    : Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isDownloading
                                ? (locale == 'en'
                                      ? "Downloading Update..."
                                      : "ဗားရှင်းအသစ် ဒေါင်းလုဒ်ဆွဲနေသည်...")
                                : (locale == 'en'
                                      ? "Update Available"
                                      : "ဗားရှင်းအသစ် ရှိနေပါသည်"),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${locale == 'en' ? 'Version' : 'ဗားရှင်း'} ${widget.version.versionCode}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (!_isDownloading &&
                              widget.version.releaseNotes != null &&
                              widget.version.releaseNotes!.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                locale == 'en'
                                    ? "WHAT'S NEW"
                                    : "ဘာတွေအသစ်ပါဝင်လာလဲ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 150),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  widget.version.releaseNotes!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (_isDownloading) ...[
                            Column(
                              children: [
                                _progress == -1
                                    ? const LinearProgressIndicator(
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.redAccent,
                                            ),
                                        minHeight: 12,
                                      )
                                    : LinearProgressIndicator(
                                        value: _progress,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.05),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.redAccent,
                                            ),
                                        minHeight: 12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                const SizedBox(height: 12),
                                Text(
                                  _progress == -1
                                      ? (locale == 'en'
                                            ? 'Downloading...'
                                            : 'ဒေါင်းလုဒ်ဆွဲနေသည်...')
                                      : "${(_progress * 100).toInt()}% ${locale == 'en' ? 'Downloaded' : 'ဒေါင်းလုဒ်ဆွဲပြီးပါပြီ'}",
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: _startDownload,
                                        child: Text(
                                          locale == 'en'
                                              ? "RETRY"
                                              : "ပြန်ကြိုးစားမည်",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _launchLegacyURL,
                                        child: Text(
                                          locale == 'en'
                                              ? "BROWSER"
                                              : "ဘရောက်ဇာမှဖွင့်ရန်",
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // ── Primary Action Button ────────────────────────────
                          if (!_isDownloading)
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE53935),
                                    Color(0xFFD32F2F),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _launchLegacyURL,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  locale == 'en'
                                      ? "UPDATE NOW"
                                      : "ယခုပဲဗားရှင်းမြှင့်မည်",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),

                          if (!_isDownloading &&
                              !widget.version.isMandatory) ...[
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white38,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: Text(
                                locale == 'en' ? "LATER" : "နောက်မှ",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
