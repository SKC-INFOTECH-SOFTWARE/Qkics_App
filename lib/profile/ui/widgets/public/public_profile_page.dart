import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/booking/expert_slots_page.dart';
import 'package:shimmer/shimmer.dart';

import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/profile/ui/widgets/profile_header.dart';
import 'package:q_kics/profile/ui/widgets/posts_tab.dart';
import 'package:q_kics/profile/ui/widgets/about_tab.dart';
import 'package:q_kics/profile/utils/public_profile_mapper.dart';

import 'package:q_kics/providers/public_profile_provider.dart';

class PublicProfilePage extends StatelessWidget {
  final String username;

  const PublicProfilePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider<PublicProfileProvider>(
      create: (_) => PublicProfileProvider()..fetchPublicProfile(username),
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Consumer<PublicProfileProvider>(
          builder: (_, provider, __) {
            // ================= LOADING =================
            if (provider.isLoading) {
              return _PublicProfileShimmer(theme: theme);
            }

            // ================= ERROR =================
            if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            }

            // ================= EMPTY =================
            if (provider.response == null) {
              return const Center(child: Text('Profile not found'));
            }

            // ================= MAP PROFILE =================
            final UserProfile publicUserProfile = provider.response!
                .toUserProfile();

            final bool showAbout =
                publicUserProfile.userType == 'expert' ||
                publicUserProfile.userType == 'entrepreneur' ||
                publicUserProfile.userType == 'investor';

            final int tabCount = showAbout ? 2 : 1;

            return DefaultTabController(
              length: tabCount,
              child: CustomScrollView(
                slivers: [
                  // ================= HEADER =================
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      profile: publicUserProfile,
                      isPublicView: true,

                      // ✅ PUBLIC EXPERT → VIEW SLOTS
                      onViewSlotsTap: publicUserProfile.userType == 'expert'
                          ? () {
                              final expertUserUuid =
                                  provider.response!.profile.user.uuid;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExpertSlotsPage(
                                    expertUuid: expertUserUuid, // ✅ FIXED
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),

                  // ================= TABS =================
                  SliverToBoxAdapter(
                    child: TabBar(
                      tabs: [
                        const Tab(text: 'Posts'),
                        if (showAbout) const Tab(text: 'About'),
                      ],
                    ),
                  ),

                  // ================= TAB CONTENT =================
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: TabBarView(
                      children: [
                        // POSTS
                        PostsTab(posts: provider.posts),
                        // ABOUT (ONLY EXPERT / ENTREPRENEUR)
                        if (showAbout)
                          AboutTab(
                            isPublicView: true,
                            publicProfile: publicUserProfile,
                            publicRoleProfile: provider.response!.profile,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PublicProfileShimmer extends StatelessWidget {
  final ThemeData theme;

  const _PublicProfileShimmer({required this.theme});

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.surfaceVariant;
    final highlightColor = theme.colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              childCount: 5,
            ),
          ),
        ],
      ),
    );
  }
}
