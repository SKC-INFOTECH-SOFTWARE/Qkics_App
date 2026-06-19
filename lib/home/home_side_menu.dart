import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/booking/booking_experts_page.dart';
import 'package:q_kics/booking/sessions_page.dart';
import 'package:q_kics/booking/user_bookings_page.dart';
import 'package:q_kics/profile/ui/authorized_profiles_page.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/chat/screens/chat_rooms_page.dart';
import 'package:q_kics/home/knowledge_hub_posts_page.dart';
import 'package:q_kics/profile/ui/settings_page.dart';
import 'package:q_kics/subscriptions/providers/subscription_provider.dart';
import 'package:q_kics/subscriptions/ui/active_subscription_page.dart';
import 'package:q_kics/subscriptions/ui/subscription_plans_page.dart';

class HomeSideMenu extends StatefulWidget {
  const HomeSideMenu({super.key});

  @override
  State<HomeSideMenu> createState() => _HomeSideMenuState();
}

class _HomeSideMenuState extends State<HomeSideMenu> {
  bool _isEntrepreneurialExpanded = false;

  @override
  void initState() {
    super.initState();
    // Load the user's active subscription so the drawer can show their current
    // plan. Only fetch if we don't already have it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sub = context.read<SubscriptionProvider>();
      if (sub.activeSubscription == null) {
        sub.fetchActiveSubscription();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = Provider.of<ApiProvider>(context);
    final user = api.currentUser;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(context, user),

          /// ================= MENU ITEMS =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                _sectionLabel(context, "Explore"),

                /// ================= ENTREPRENEURIAL CONNECT =================
                _drawerItem(
                  context,
                  Icons.rocket_launch_outlined,
                  "Entrepreneurial Connect",
                  selected: _isEntrepreneurialExpanded,
                  trailing: AnimatedRotation(
                    turns: _isEntrepreneurialExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more, size: 22),
                  ),
                  onTap: () => setState(
                    () =>
                        _isEntrepreneurialExpanded = !_isEntrepreneurialExpanded,
                  ),
                ),

                /// Expandable Section
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      _drawerItem(
                        context,
                        Icons.auto_stories_outlined,
                        "Knowledge Hub",
                        indented: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KnowledgeHubPostsPage(),
                            ),
                          );
                        },
                      ),
                      _drawerItem(
                        context,
                        Icons.handshake_outlined,
                        "Investor Linkup",
                        indented: true,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthorizedProfilesPage(
                                onlyInvestors: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  crossFadeState: _isEntrepreneurialExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),

                /// Messages
                _drawerItem(
                  context,
                  Icons.message_outlined,
                  "Messages",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatRoomsPage()),
                    );
                  },
                ),

                /// Companies
                _drawerItem(
                  context,
                  Icons.business_outlined,
                  "Companies",
                  onTap: () {
                    final nav = context.read<NavigationProvider>();
                    Navigator.pop(context); // close drawer
                    nav.goCompanies();
                  },
                ),

                /// Experts Booking
                _drawerItem(
                  context,
                  Icons.person_search_outlined,
                  "Experts",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookingExpertsPage(),
                      ),
                    );
                  },
                ),

                /// My Sessions — upcoming + live video calls
                _sessionsItem(context),

                /// Booking History
                _drawerItem(
                  context,
                  Icons.history,
                  "Booking history",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserBookingsPage(),
                      ),
                    );
                  },
                ),

                _sectionLabel(context, "Account"),

                /// Subscription — highlighted card showing the current plan
                _subscriptionItem(context),

                /// Settings
                _drawerItem(
                  context,
                  Icons.settings_outlined,
                  "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= Header =================
  Widget _buildHeader(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final double scale = isTablet ? 1.3 : 1.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topInset + 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.14),
            cs.primary.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final nav = context.read<NavigationProvider>();
            Navigator.pop(context); // close drawer
            nav.goProfile();
          },
          child: Padding(
            padding: EdgeInsets.all(8 * scale),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: _buildAvatar(
                    context,
                    user?.profileImage,
                    user?.username ?? "",
                    30 * scale,
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? "Guest User",
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      //user type badge
                      if (user?.userType != null) ...[
                        SizedBox(height: 4 * scale),
                        _pill(
                          context,
                          user!.userType.toUpperCase(),
                          //change color based on user type
                          user.userType == "entrepreneur"
                              ? Colors.green
                              : user.userType == "investor"
                                  ? Colors.purple
                                  :user.userType == "expert"
                                      ? Colors.blue
                                      :
                          cs.primary,
                          scale,
                        ),
                      ],  
                      
                      // const SizedBox(height: 2),
                      // Text(
                      //   user?.email ?? "user@example.com",
                      //   style: TextStyle(
                      //     fontSize: 12.5 * scale,
                      //     color: cs.onSurfaceVariant,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                    ],
                  ),
                ),
                Container(
                  width: 32 * scale,
                  height: 32 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 22 * scale,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= Section Label =================
  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final double scale = isTablet ? 1.25 : 1.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16 * scale, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// ================= My Sessions Item =================
  /// Shows a "LIVE" badge when at least one session is happening right now.
  Widget _sessionsItem(BuildContext context) {
    final api = Provider.of<ApiProvider>(context, listen: false);
    final provider = Provider.of<BookingProvider>(context);
    final currentUserId = api.currentUser?.id;

    // Count live sessions (confirmed + currently within start–end window)
    int liveCount = 0;
    if (currentUserId != null) {
      final now = DateTime.now();
      final all = {...provider.userBookings, ...provider.expertBookings};
      liveCount = all
          .where((b) =>
              b.isConfirmed &&
              (b.user == currentUserId || b.expert == currentUserId) &&
              !now.isBefore(b.startDatetime.toLocal()) &&
              !now.isAfter(b.endDatetime.toLocal()))
          .length;
    }

    return _drawerItem(
      context,
      Icons.video_camera_front_outlined,
      "My Sessions",
      badge: liveCount > 0 ? "LIVE" : null,
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SessionsPage()),
        );
      },
    );
  }

  /// ================= Subscription Item =================
  /// A highlighted card. When the user has an active plan it shows the plan name
  /// + days remaining and opens the active-subscription screen; otherwise it
  /// invites them to browse plans.
  Widget _subscriptionItem(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subProvider = context.watch<SubscriptionProvider>();
    final active = subProvider.activeSubscription;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final double scale = isTablet ? 1.25 : 1.0;

    final bool hasPlan = active != null && active.isActive;
    final int daysLeft = hasPlan
        ? active.endDate.difference(DateTime.now()).inDays
        : 0;

    final subtitle = hasPlan
        ? (daysLeft > 0
            ? '${active.plan.name} · $daysLeft days left'
            : active.plan.name)
        : 'Unlock premium features';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => hasPlan
                    ? const ActiveSubscriptionPage()
                    : const SubscriptionPlansPage(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * scale,
              vertical: 12 * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: hasPlan ? 0.18 : 0.10),
                  cs.primary.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * scale),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.workspace_premium,
                    size: 20 * scale,
                    color: cs.primary,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hasPlan ? 'Subscription' : 'Go Premium',
                            style: TextStyle(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          if (hasPlan) ...[
                            SizedBox(width: 6 * scale),
                            _pill(context, "ACTIVE", cs.primary, scale),
                          ],
                        ],
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20 * scale,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= Drawer Item =================
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Widget? trailing,
    String? badge,
    bool selected = false,
    bool indented = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final double scale = isTablet ? 1.3 : 1.0;
    final Color fg = selected ? cs.primary : cs.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(indented ? 24 : 8, 2, 8, 2),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: EdgeInsets.symmetric(horizontal: 12 * scale),
        horizontalTitleGap: 10 * scale,
        minLeadingWidth: 0,
        dense: !isTablet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        selected: selected,
        selectedTileColor: cs.primary.withValues(alpha: 0.10),
        leading: Icon(
          icon,
          size: 22 * scale,
          color: selected ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15 * scale,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 8 * scale),
              _pill(context, badge, Colors.red, scale, filled: true),
            ],
          ],
        ),
        trailing: trailing,
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$title – Coming Soon!")),
              );
            },
      ),
    );
  }

  /// ================= Pill / Badge =================
  Widget _pill(
    BuildContext context,
    String text,
    Color color,
    double scale, {
    bool filled = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 10 * scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// ================= Avatar =================
  Widget _buildAvatar(
    BuildContext context,
    String? imageUrl,
    String username,
    double radius,
  ) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "U";

    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    if (!hasImage) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 1.1,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(initial),
          ),
        ),
      ),
    );
  }
}
