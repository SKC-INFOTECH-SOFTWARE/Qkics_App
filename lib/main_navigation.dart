// lib/screens/main_navigation.dart (Bottom-Anchored with Profile Avatar)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/home/create_post_page.dart';
import 'package:q_kics/home/home.dart';
import 'package:q_kics/home/search_page.dart';
import 'package:q_kics/profile/profile_route.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/screens/notifications_page.dart';

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
      const SearchPage(),
      const CreatePostPage(),
      const NotificationsPage(),
      ProfileRoute(onBarsVisibilityChanged: _onBarsVisibilityChanged),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: nav.index, children: pages),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 2),
        child: Padding(
          padding: EdgeInsets.fromLTRB(paddingX, 0, paddingX, 24),
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
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search_rounded,
                          isSelected: nav.index == 1,
                          onTap: () => nav.setIndex(1),
                        ),
                        _NavItem(
                          icon: Icons.add_box_outlined,
                          activeIcon: Icons.add_box_rounded,
                          isSelected: nav.index == 2,
                          onTap: () => nav.setIndex(2),
                        ),
                        _NavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications_rounded,
                          isSelected: nav.index == 3,
                          onTap: () => nav.setIndex(3),
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
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
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
                child: _buildIcon(context, colorScheme),
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
          : colorScheme.onSurface.withOpacity(0.6),
    );
  }
}
