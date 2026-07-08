import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    Timer(const Duration(milliseconds: 2000), () {
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
    return Scaffold(
      backgroundColor: kPrimary,
      body: Stack(
        children: [
          // ── Full-screen splash image ──────────────────────────────────────
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/splash.svg',
              fit: BoxFit.cover,
            ).animate().fadeIn(duration: 600.ms),
          ),

          // ── Loading dots at bottom ───────────────────────────────────────
          Positioned(
            bottom: 52,
            left: 0,
            right: 0,
            child: _LoadingDots().animate().fadeIn(
              delay: 800.ms,
              duration: 400.ms,
            ),
          ),
        ],
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
                color: Colors.white.withValues(alpha: 0.4 + 0.6 * scale),
              ),
            );
          },
        );
      }),
    );
  }
}
