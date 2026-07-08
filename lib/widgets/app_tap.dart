import 'package:flutter/cupertino.dart';

/// Drop-in replacement for [GestureDetector] that also shows the pointer
/// (hand) cursor on web/desktop whenever a tap handler is set, so every
/// clickable element in the app hovers correctly in a browser.
class AppTap extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final HitTestBehavior? behavior;

  const AppTap({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    final interactive =
        onTap != null || onLongPress != null || onDoubleTap != null;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        behavior: behavior,
        child: child,
      ),
    );
  }
}
