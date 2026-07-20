import 'package:flutter/material.dart';

/// Shows a top-anchored success/error banner (white card, black circular
/// check icon, drop shadow) matching the app's toast design — independent
/// of whatever Scaffold happens to be current, and independent of any
/// platform-specific toast plugin (works identically on Android, iOS, and
/// Windows since it's built from plain Flutter widgets via an Overlay).
class AppMessenger {
  AppMessenger._();

  /// Passed into GoRouter(navigatorKey: ...) in app_router.dart so this
  /// class can reach the app's Overlay from anywhere, including from
  /// inside Provider callbacks that don't have a screen's BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showSuccess(String message) => _show(message, isError: false);
  static void showError(String message) => _show(message, isError: true);

  static void _show(String message, {required bool isError}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastBanner(
        message: message,
        isError: isError,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _ToastBanner extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;
  const _ToastBanner({required this.message, required this.isError, required this.onDismiss});

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 18, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: widget.isError ? const Color(0xFFE03B3B) : Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.isError ? Icons.close : Icons.check, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
