import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/Auth/login.dart';
import 'package:q_kics/booking/booking_experts_page.dart';
import 'package:q_kics/booking/user_bookings_page.dart';
import 'package:q_kics/profile/profile_route.dart';
import 'package:q_kics/profile/ui/authorized_profiles_page.dart';
import 'package:q_kics/documents/ui/knowledge_hub_page.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/chat/screens/chat_rooms_page.dart';
import 'package:q_kics/profile/ui/settings_page.dart';

class HomeSideMenu extends StatelessWidget {
  const HomeSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final api = Provider.of<ApiProvider>(context);
    final user = api.currentUser;
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.4 : 1.0;
    return Container(
      //width: 80 * scale,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20 * scale,
              60 * scale,
              20 * scale,
              24 * scale,
            ),
            color: colorScheme.primary.withOpacity(0.05),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileRoute()),
                );
              },
              child: Row(
                children: [
                  _buildAvatar(
                    context,
                    user?.profileImage,
                    user?.username ?? "",
                    36 * scale,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? "Guest User",
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.email ?? "user@example.com",
                          style: TextStyle(
                            fontSize: 13 * scale,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 28 * scale),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                SizedBox(height: isTablet ? 8 * scale : 0),

                // SizedBox(height: isTablet ? 8 * scale : 0),

                // _drawerItem(
                //   context,
                //   Icons.bar_chart_outlined,
                //   "Your content & stats",
                // ),
                // SizedBox(height: isTablet ? 8 * scale : 0),
                // _drawerItem(context, Icons.bookmark_border, "Bookmarks"),
                // SizedBox(height: isTablet ? 8 * scale : 0),
                // _drawerItem(context, Icons.edit_outlined, "Drafts"),

                // ✅ KNOWLEDGE HUB (DOCUMENTS)
                _drawerItem(
                  context,
                  Icons.auto_stories_outlined,
                  "Knowledge Hub",
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KnowledgeHubPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: isTablet ? 8 * scale : 0),

                // ✅ AUTHORIZED PROFILES
                _drawerItem(
                  context,
                  Icons.people_alt_outlined,
                  "Authorized Profiles",
                  onTap: () {
                    // Close drawer if we were in a drawer context, but here we might just navigate
                    // For side menu, we don't need to pop.
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthorizedProfilesPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: isTablet ? 8 * scale : 0),

                // ✅ BOOKINGS REDIRECTION
                _drawerItem(
                  context,
                  Icons.calendar_today_outlined,
                  "Bookings",
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
                SizedBox(height: isTablet ? 8 * scale : 0),

                _drawerItem(
                  context,
                  Icons
                      .history, // Changed icon to match "Booking history" better if needed, or keep logout icon if that was intentional?
                  // In original code it was Icons.logout for "Booking history" which seems like a mistake, I'll use history.
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

                Divider(
                  height: 32 * scale,
                  indent: 16 * scale,
                  endIndent: 16 * scale,
                ),

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
                // _drawerItem(
                //   context,
                //   Icons.logout,
                //   "Logout",
                //   onTap: () async {
                //     await api.logout();
                //     Navigator.pushReplacement(
                //       context,
                //       MaterialPageRoute(builder: (_) => const LoginPage()),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,

    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 24 * (MediaQuery.of(context).size.width >= 600 ? 1.5 : 1.0),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16 * (MediaQuery.of(context).size.width >= 600 ? 1.5 : 1.0),
        ),
      ),
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("$title – Coming Soon!")));
          },
    );
  }

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
        ).colorScheme.primary.withOpacity(0.15),
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
    final bustedUrl = '$imageUrl?ts=${DateTime.now().millisecondsSinceEpoch}';
    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: bustedUrl,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          placeholder: (_, __) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.15),
            child: Text(initial),
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.15),
            child: Text(initial),
          ),
        ),
      ),
    );
  }
}
