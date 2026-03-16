import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:msloyalty/Providers/settings_provider.dart';
import 'package:msloyalty/Helpers/app_localizations.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  String _pin = "";
  String _confirmPin = "";
  bool _isConfirming = false;
  String _errorMessage = "";

  void _handleKeyPress(String key) {
    if (_pin.length >= 4 && key != "back") return;

    setState(() {
      _errorMessage = "";
      if (key == "back") {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        _pin += key;
        if (_pin.length == 4) {
          // Small delay to show the last dot before processing
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _handlePinComplete();
          });
        }
      }
    });
  }

  void _handlePinComplete() async {
    if (!_isConfirming) {
      // Move to confirmation step
      setState(() {
        _confirmPin = _pin;
        _pin = "";
        _isConfirming = true;
      });
    } else {
      // Check if pins match
      if (_pin == _confirmPin) {
        try {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          await settings.setPin(_pin);
          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          setState(() {
            _errorMessage = "Secure storage error: $e";
            _pin = "";
          });
        }
      } else {
        setState(() {
          _pin = "";
          _errorMessage = "PINs do not match. Try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final locale = settings.locale;

    return Scaffold(
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
            bottom: -50,
            left: -50,
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
                // ── Header ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConfirming 
                          ? (locale == 'en' ? "Confirm PIN" : "PIN အတည်ပြုပါ")
                          : (locale == 'en' ? "Setup PIN" : "PIN အသစ်ပေးပါ"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // ── PIN Indicators ──────────────────────────────────────────
                Column(
                  children: [
                    Text(
                      _isConfirming
                        ? (locale == 'en' ? "Re-enter your 4-digit PIN" : "PIN နံပါတ်ကို ထပ်မံရိုက်ထည့်ပါ")
                        : (locale == 'en' ? "Create your 4-digit PIN" : "ဂဏန်း ၄ လုံးပါသော PIN နံပါတ်တစ်ခု ဖန်တီးပါ"),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),
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
