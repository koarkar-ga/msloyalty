import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';

class PinVerifyPage extends StatefulWidget {
  final bool isForUnlock;
  const PinVerifyPage({super.key, this.isForUnlock = false});

  @override
  State<PinVerifyPage> createState() => _PinVerifyPageState();
}

class _PinVerifyPageState extends State<PinVerifyPage> {
  String _pin = "";
  String _errorMessage = "";

  void _handleKeyPress(String key) {
    setState(() {
      _errorMessage = "";
      if (key == "back") {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_pin.length < 4) {
          _pin += key;
          if (_pin.length == 4) {
            _handlePinComplete();
          }
        }
      }
    });
  }

  void _handlePinComplete() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final savedPin = await settings.getPin();

    if (_pin == savedPin) {
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _pin = "";
        _errorMessage = "Incorrect PIN. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale;

    return WillPopScope(
      onWillPop: () async => !widget.isForUnlock,
      child: Scaffold(
        body: Stack(
          children: [
            // ── Background Gradient ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A192F), Color(0xFF132B4F)],
                ),
              ),
            ),

            // ── Glowing Orbs ──────────────────────────────────────────────────
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1B4F72).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Header (only if not for mandatory unlock) ──────────────────
                  if (!widget.isForUnlock)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(flex: 1),

                  // ── PIN Indicators ──────────────────────────────────────────
                  Column(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 60),
                      const SizedBox(height: 24),
                      Text(
                        locale == 'en' ? "Security Check" : "လုံခြုံရေးစစ်ဆေးခြင်း",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        locale == 'en' ? "Enter your 4-digit PIN" : "PIN နံပါတ်ကို ရိုက်ထည့်ပါ",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          bool filled = index < _pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? Colors.red : Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: filled ? Colors.red : Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: filled ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ] : [],
                            ),
                          );
                        }),
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                      ],
                    ],
                  ),

                  const Spacer(flex: 2),

                  // ── Keypad ──────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ...List.generate(9, (index) => _buildKey((index + 1).toString())),
                        const SizedBox.shrink(),
                        _buildKey("0"),
                        _buildKey("back", icon: Icons.backspace_outlined),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String value, {IconData? icon}) {
    return InkWell(
      onTap: () => _handleKeyPress(value),
      borderRadius: BorderRadius.circular(50),
      child: Center(
        child: icon != null
          ? Icon(icon, color: Colors.white, size: 24)
          : Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }
}
