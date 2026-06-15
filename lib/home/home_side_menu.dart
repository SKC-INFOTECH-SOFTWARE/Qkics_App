import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:q_kics/Auth/login.dart';
import 'package:q_kics/booking/booking_experts_page.dart';
import 'package:q_kics/booking/sessions_page.dart';
import 'package:q_kics/booking/user_bookings_page.dart';
import 'package:q_kics/profile/profile_route.dart';
import 'package:q_kics/profile/ui/authorized_profiles_page.dart';
import 'package:q_kics/documents/ui/knowledge_hub_page.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/chat/screens/chat_rooms_page.dart';
import 'package:q_kics/home/knowledge_hub_posts_page.dart';
import 'package:q_kics/profile/ui/settings_page.dart';

class HomeSideMenu extends StatefulWidget {
  const HomeSideMenu({super.key});

  @override
  State<HomeSideMenu> createState() => _HomeSideMenuState();
}

class _HomeSideMenuState extends State<HomeSideMenu> {
  bool _isEntrepreneurialExpanded = false;

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
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          /// ================= HEADER =================
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

          /// ================= MENU ITEMS =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                /// ================= ENTREPRENEURIAL CONNECT =================
                ListTile(
                  selected: _isEntrepreneurialExpanded,
                  title: const Text(
                    "Entrepreneurial Connect",
                    style: TextStyle(),
                  ),
                  trailing: AnimatedRotation(
                    turns: _isEntrepreneurialExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more),
                  ),
                  onTap: () {
                    setState(() {
                      _isEntrepreneurialExpanded = !_isEntrepreneurialExpanded;
                    });
                  },
                ),

                /// Expandable Section
                AnimatedCrossFade(
                  firstChild: const SizedBox(),
                  secondChild: Column(
                    children: [
                      /// Knowledge Hub
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: _drawerItem(
                          context,
                          Icons.auto_stories_outlined,
                          "Knowledge Hub",
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
                      ),

                      /// Hub Posts
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 32),
                      //   child: _drawerItem(
                      //     context,
                      //     Icons.forum_outlined,
                      //     "Hub Posts",
                      //     onTap: () {
                      //       Navigator.pop(context);
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (_) => const KnowledgeHubPostsPage(),
                      //         ),
                      //       );
                      //     },
                      //   ),
                      // ),

                      /// Investor Linkup
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: _drawerItem(
                          context,
                          Icons.handshake_outlined,
                          "Investor Linkup",
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
                      ),
                    ],
                  ),
                  crossFadeState: _isEntrepreneurialExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),

                const SizedBox(height: 8),

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

                const SizedBox(height: 8),

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

                const SizedBox(height: 8),

                /// My Sessions — upcoming + live video calls
                _sessionsItem(context),

                const SizedBox(height: 8),

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

                const Divider(height: 32),

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

  /// ================= My Sessions Item =================
  /// Shows a "LIVE" badge when at least one session is happening right now.
  Widget _sessionsItem(BuildContext context) {
    final api = Provider.of<ApiProvider>(context, listen: false);
    final provider = Provider.of<BookingProvider>(context);
    final currentUserId = api.currentUser?.id;
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final double s = isTablet ? 1.5 : 1.0;

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

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.video_camera_front_outlined, size: 24 * s),
          if (liveCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 10 * s,
                height: 10 * s,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text('My Sessions', style: TextStyle(fontSize: 16 * s)),
          if (liveCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10 * s,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SessionsPage()),
        );
      },
    );
  }

  /// ================= Drawer Item =================
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return ListTile(
      leading: Icon(icon, size: 24 * (isTablet ? 1.5 : 1.0)),
      title: Text(
        title,
        style: TextStyle(fontSize: 16 * (isTablet ? 1.5 : 1.0)),
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
        ),
      ),
    );
  }
}
