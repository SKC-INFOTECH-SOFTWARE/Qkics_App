import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ─────────────────────────────────────────────────────────────
/// APP ERROR TYPES (SAME FILE – GLOBAL)
/// ─────────────────────────────────────────────────────────────
enum AppErrorType {
  noInternet,
  serverDown,
  timeout,
  unauthorized,
  unknown,
}

/// ─────────────────────────────────────────────────────────────
/// SERVER RESPONSE MANAGEMENT UI (LOTTIE BASED)
/// ─────────────────────────────────────────────────────────────
class ServerResponsePage extends StatelessWidget {
  final AppErrorType errorType;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  const ServerResponsePage({
    super.key,
    required this.errorType,
    this.onRetry,
    this.onGoHome,
  });

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = _isTablet(context);

    final _ErrorContent content = _getContent(errorType);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 520 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 48 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ───────────── LOTTIE ANIMATION ─────────────
                  Lottie.asset(
                    content.lottieAsset,
                    height: isTablet ? 380 : 280,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  // ───────────── TITLE ─────────────
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 30 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ───────────── MESSAGE ─────────────
                  Text(
                    content.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ───────────── RETRY BUTTON ─────────────
                  if (onRetry != null)
                    SizedBox(
                      width: isTablet ? 280 : double.infinity,
                      height: isTablet ? 54 : 48,
                      child: FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(
                          "Retry",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  if (onRetry != null && onGoHome != null)
                    const SizedBox(height: 12),

                  // ˛  
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ─────────────────────────────────────────────────────────────
  /// ERROR CONTENT MAPPER
  /// ─────────────────────────────────────────────────────────────
  _ErrorContent _getContent(AppErrorType type) {
    switch (type) {
      case AppErrorType.noInternet:
        return const _ErrorContent(
          lottieAsset: 'assets/lottie/no_internet.json',
          title: "No Internet Connection",
          message:
              "You're offline.\nPlease check your network and try again.",
        );

      case AppErrorType.serverDown:
        return const _ErrorContent(
          lottieAsset: 'assets/lottie/server_down.json',
          title: "Server Unavailable",
          message:
              "Our servers are taking a break.\nPlease try again shortly.",
        );

      case AppErrorType.timeout:
        return const _ErrorContent(
          lottieAsset: 'assets/lottie/timeout.json',
          title: "Request Timeout",
          message:
              "The request took too long.\nTap retry to try again.",
        );

      case AppErrorType.unauthorized:
        return const _ErrorContent(
          lottieAsset: 'assets/lottie/session_expired.json',
          title: "Session Expired",
          message:
              "Your session has expired.\nPlease login again.",
        );

      case AppErrorType.unknown:
      default:
        return const _ErrorContent(
          lottieAsset: 'assets/lottie/error.json',
          title: "Something Went Wrong",
          message:
              "An unexpected error occurred.\nPlease try again.",
        );
    }
  }
}

/// ─────────────────────────────────────────────────────────────
/// INTERNAL MODEL
/// ─────────────────────────────────────────────────────────────
class _ErrorContent {
  final String lottieAsset;
  final String title;
  final String message;

  const _ErrorContent({
    required this.lottieAsset,
    required this.title,
    required this.message,
  });
}
