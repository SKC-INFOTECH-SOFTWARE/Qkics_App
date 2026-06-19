// lib/screens/main_navigation.dart (Bottom-Anchored with Profile Avatar)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/home/home.dart';
import 'package:q_kics/home/knowledge_hub_posts_page.dart';
import 'package:q_kics/profile/profile_route.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/providers/notification_provider.dart';
import 'package:q_kics/screens/notifications_page.dart';
import 'package:q_kics/companies/companies_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:q_kics/call/providers/call_notifier.dart';
import 'package:q_kics/call/screens/call_screen.dart';
import 'package:q_kics/call/utils/web_fullscreen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final ScrollController _homeScrollController = ScrollController();
  bool _isBottomBarVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  void _onBarsVisibilityChanged(bool visible) {
    if (_isBottomBarVisible != visible) {
      setState(() {
        _isBottomBarVisible = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Calculate tab width for 5 items
    // Using a slightly smaller effective width to account for padding/margins if needed
    // But since it's a row with spaceAround/Evenly inside a container,
    // we should base logic on the container's width.

    final isTablet = screenWidth >= 600;
    final double paddingX = isTablet ? 32.0 : 16.0;
    final double navBarWidth = screenWidth - (paddingX * 2);
    final double tabWidth = navBarWidth / 5; // 5 items

    final pages = [
      HomePage(
        scrollController: _homeScrollController,
        onBarsVisibilityChanged: _onBarsVisibilityChanged,
      ),
      const KnowledgeHubPostsPage(embedded: true),
      CompaniesPage(onBarsVisibilityChanged: _onBarsVisibilityChanged),
      NotificationsPage(onBarsVisibilityChanged: _onBarsVisibilityChanged),
      ProfileRoute(onBarsVisibilityChanged: _onBarsVisibilityChanged),
    ];

    return PopScope(
      // Allow the system to pop (exit) only when already on the home tab.
      canPop: nav.index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) nav.setIndex(0);
      },
      child: Stack(
      children: [
      Scaffold(
      extendBody: true,
      body: IndexedStack(index: nav.index, children: pages),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 2),
        child: Padding(
          padding: EdgeInsets.fromLTRB(paddingX, 0, paddingX, 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30), // Pill shape
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64, // Floating bar height
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Moving Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.elasticOut,
                      top: 0,
                      bottom:
                          0, // Fill vertically for alignment, but we'll center a dot or line
                      left: (nav.index * tabWidth),
                      width: tabWidth,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Can put a dot or line here.
                            // Let's do a top active line or bottom dot?
                            // User asked for "latest design".
                            // Often this means an active pill or bubble behind the icon
                            // or a glowing dot at bottom.

                            // Let's go with a bottom glowing dot for a clean look
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Icons
                    Row(
                      children: [
                        _NavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          isSelected: nav.index == 0,
                          onTap: () => nav.setIndex(0),
                        ),
                        _NavItem(
                          icon: Icons.auto_stories_outlined,
                          activeIcon: Icons.auto_stories_rounded,
                          isSelected: nav.index == 1,
                          onTap: () => nav.setIndex(1),
                        ),
                        _NavItem(
                          icon: Icons.business_center_outlined,
                          activeIcon: Icons.business_center_rounded,
                          isSelected: nav.index == 2,
                          onTap: () => nav.setIndex(2),
                        ),
                        _NavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications_rounded,
                          isSelected: nav.index == 3,
                          onTap: () => nav.setIndex(3),
                          badgeCount: context
                              .watch<NotificationProvider>()
                              .unreadCount,
                        ),
                        _NavItem(
                          icon: Icons.person_outlined,
                          activeIcon: Icons.person_rounded,
                          imageUrl: profileProvider.profile?.profilePicture,
                          isSelected: nav.index == 4,
                          onTap: () => nav.setIndex(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ), // end Scaffold
      const _InCallBanner(),
    ], // end Stack children
    ), // end Stack
    ); // end PopScope
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating "Return to call" banner — visible when the user minimized the call
// by pressing back during screen share.
// ─────────────────────────────────────────────────────────────────────────────
class _InCallBanner extends ConsumerWidget {
  const _InCallBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(
      callNotifierProvider.select((s) => s.isConnected),
    );
    final isMinimized = ref.watch(
      callNotifierProvider.select((s) => s.isMinimized),
    );
    final isSharing = ref.watch(
      callNotifierProvider.select((s) => s.isScreenSharing),
    );

    if (!isConnected || !isMinimized) return const SizedBox.shrink();

    return Positioned(
      bottom: 96, // just above the floating nav bar
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // Inside a tap handler — safe to request fullscreen (user gesture).
          if (kIsWeb) requestCallFullscreen();
          final notifier = ref.read(callNotifierProvider.notifier);
          final params = notifier.callScreenParams;
          if (params == null) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CallScreen(
                roomId: params.roomId,
                authToken: params.authToken,
                currentUserId: params.currentUserId,
                currentUserName: params.currentUserName,
                meetingDurationMinutes: params.meetingDurationMinutes,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF6C63FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.screen_share_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isSharing ? 'Screen sharing in progress' : 'Call in progress',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Return',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon moves up slightly when selected/animated
            AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: isSelected ? const Offset(0, -0.1) : Offset.zero,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.1 : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildIcon(context, colorScheme),
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, ColorScheme colorScheme) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: colorScheme.surfaceContainerHighest),
            errorWidget: (context, url, error) => Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Icon(
      isSelected ? activeIcon : icon,
      size: 26,
      color: isSelected
          ? colorScheme.primary
          : colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }
}
