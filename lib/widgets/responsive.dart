import 'package:flutter/widgets.dart';

/// Width breakpoints used to adapt layouts for wider (web/desktop) viewports.
class Breakpoints {
  static const double tablet = 700;
  static const double desktop = 1024;
}

extension ResponsiveX on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  /// True once the viewport is wide enough to stop looking like a phone
  /// (tablet, desktop browser window, etc).
  bool get isTablet => _screenWidth >= Breakpoints.tablet;

  /// True once the viewport is wide enough for the persistent sidebar shell.
  bool get isDesktop => _screenWidth >= Breakpoints.desktop;
}

/// Centers [child] and caps its width on wide viewports so content reads as
/// a web page instead of a phone screen stretched edge-to-edge.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
