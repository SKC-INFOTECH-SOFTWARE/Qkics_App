import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:q_kics/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutQuart),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });

    // Navigate to AuthWrapper after 2.5 seconds
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Dynamic Mesh Gradient Background
          _buildMeshGradient(size),

          // Main content without the card for a more professional integrated feel
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with pulse effect
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value * _pulseAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/loader.gif',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              // Elegant Tagline
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(opacity: _fadeAnimation.value, child: child);
                },
                child: Text(
                  'Expertise • Innovation • Investment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),

          // Subtle loader and Branding Footer
          Positioned(
            bottom: 60,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(opacity: _fadeAnimation.value, child: child);
              },
              child: Column(
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'POWERED BY Q-KICS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshGradient(Size size) {
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          _buildGradientCircle(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            offset: Offset(size.width * 0.1, size.height * 0.15),
            radius: 200,
          ),
          _buildGradientCircle(
            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            offset: Offset(size.width * 0.9, size.height * 0.2),
            radius: 250,
          ),
          _buildGradientCircle(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.08),
            offset: Offset(size.width * 0.2, size.height * 0.85),
            radius: 220,
          ),
          _buildGradientCircle(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            offset: Offset(size.width * 0.8, size.height * 0.9),
            radius: 280,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCircle({
    required Color color,
    required Offset offset,
    required double radius,
  }) {
    return Positioned(
      left: offset.dx - radius,
      top: offset.dy - radius,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
