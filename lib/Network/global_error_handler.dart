import 'package:flutter/material.dart';
import 'server_response_page.dart';
import '../../main.dart'; // where navigatorKey is defined
import '../screens/splash_screen.dart'; // Import for navigation

class GlobalErrorHandler {
  static bool _isShowing = false;

  static void show(AppErrorType type, {VoidCallback? onRetry}) {
    if (_isShowing) return;

    // 🛡️ If the navigator is not yet ready (e.g. app just starting),
    // we use a small delay or post-frame callback to wait for it.
    if (globalNavigatorKey.currentState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        show(type, onRetry: onRetry);
      });
      return;
    }

    _isShowing = true;
    final navigator = globalNavigatorKey.currentState!;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ServerResponsePage(
          errorType: type,
          onRetry: () {
            _isShowing = false;
            // Go to AuthWrapper which decides Home or Login
            globalNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );

          },
          onGoHome: () {
            _isShowing = false;
            // Go to AuthWrapper which decides Home or Login
            globalNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (route) => false,
            );
          },
        ),
      ),
      (route) => false,
    );
  }
}
