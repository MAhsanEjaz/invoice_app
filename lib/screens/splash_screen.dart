import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:invoicemaker/constants.dart';
import 'package:invoicemaker/providers/business_provider.dart';
import 'package:invoicemaker/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../services/navigations.dart' show Navigation;
import 'business_start_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void _navigate() async {
    final businessProvider = Provider.of<BusinessProvider>(
      context,
      listen: false,
    );
    final data = await businessProvider.getString();

    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      if (data != null) {
        Navigation.clearAll(context, const HomeScreen());
      } else {
        Navigation.clearAll(context, const BusinessStartPage());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kPrimary,
      body: Stack(
        children: [
          // ── Decorative background circles ────────────────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.25,
            child: _DecorCircle(size.width * 0.7),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.2,
            child: _DecorCircle(size.width * 0.55),
          ),
          Positioned(
            top: size.height * 0.35,
            left: -size.width * 0.1,
            child: _DecorCircle(size.width * 0.3, opacity: 0.04),
          ),

          // ── Main content ─────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_fill,
                    size: 44,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.65, 0.65),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // App name
                Text(
                  'Invoice Maker',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      delay: 300.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Professional invoicing, simplified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
              ],
            ),
          ),

          // ── Loading dots at bottom ───────────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: _LoadingDots()
                .animate()
                .fadeIn(delay: 800.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle(this.size, {this.opacity = 0.07});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (1 - (2 * phase - 1).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: 0.4 + 0.6 * scale,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
