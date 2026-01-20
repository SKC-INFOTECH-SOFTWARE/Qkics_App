import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/booking/create_slot_page.dart';
import 'package:q_kics/profile/models/profile_type.dart';
import 'package:q_kics/profile/ui/upgrade/entrepreneur/entrepreneur_profile_form.dart';
import 'package:q_kics/profile/ui/upgrade/expert/expert_profile_form.dart';
import 'package:q_kics/profile/ui/upgrade/investor/investor_profile_form.dart';
import 'package:q_kics/profile/ui/upgrade/upgrade_profile_sheet.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/investor_profile_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'widgets/profile_header.dart';
import 'package:q_kics/profile/ui/widgets/posts_tab.dart';
import 'package:q_kics/profile/ui/widgets/about_tab.dart';
import 'package:q_kics/profile/ui/widgets/answers_tab.dart';
import 'package:q_kics/subscriptions/providers/subscription_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadedSubProfiles = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Preload sub profiles safely
      final expertProvider = context.read<ExpertProfileProvider>();
      final entrepreneurProvider = context.read<EntrepreneurProfileProvider>();
      final investorProvider = context.read<InvestorProfileProvider>();
      final subscriptionProvider = context.read<SubscriptionProvider>();

      await expertProvider.fetchExpertProfile();
      if (!mounted) return;
      await entrepreneurProvider.fetchEntrepreneurProfile();
      if (!mounted) return;
      await investorProvider.fetchMyProfile();
      if (!mounted) return;
      // Fetch active subscription
      await subscriptionProvider.fetchActiveSubscription();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadedSubProfiles) return;

    final profileProvider = context.read<ProfileProvider>();
    if (profileProvider.profile == null) return;

    final profileType = profileProvider.profileType;

    // Load ONLY required sub profile using post frame callback to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (profileType == ProfileType.expert) {
        context.read<ExpertProfileProvider>().fetchExpertProfile();
      }

      if (profileType == ProfileType.entrepreneur) {
        context.read<EntrepreneurProfileProvider>().fetchEntrepreneurProfile();
      }

      if (profileType == ProfileType.investor) {
        context.read<InvestorProfileProvider>().fetchMyProfile();
      }
    });

    _loadedSubProfiles = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Determine tab count logic (moved from ProfileTabs)
    final profileProvider = context.watch<ProfileProvider>();
    final isNormal = profileProvider.profileType == ProfileType.normal;
    final tabCount = isNormal ? 2 : 3;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<ProfileProvider>(
        builder: (_, provider, __) {
          if (provider.loadingProfile || provider.profile == null) {
            return _ProfileShimmer(theme: theme);
          }

          return DefaultTabController(
            length: tabCount,
            child: RefreshIndicator(
              onRefresh: () async {
                if (!mounted) return;
                _loadedSubProfiles = false;
                await context.read<ProfileProvider>().loadProfile(force: true);
              },
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    // ================= PROFILE HEADER =================
                    SliverToBoxAdapter(
                      child: ProfileHeader(
                        profile: provider.profile!,
                        isPublicView: false,

                        // ================= EXPERT SLOT CREATION =================
                        onCreateSlotsTap:
                            provider.profileType == ProfileType.expert
                            ? () async {
                                if (!mounted) return;
                                final expertProvider = context
                                    .read<ExpertProfileProvider>();

                                if (expertProvider.profile == null) {
                                  await expertProvider.fetchExpertProfile();
                                }

                                if (!mounted) return;
                                final expertUuid = expertProvider.expertUuid;

                                if (expertUuid == null || expertUuid.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Expert profile not ready"),
                                    ),
                                  );
                                  return;
                                }

                                final bookingProvider = context
                                    .read<BookingProvider>();

                                bookingProvider.setExpertUuid(expertUuid);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChangeNotifierProvider.value(
                                          value: bookingProvider,
                                          child: const CreateSlotPage(),
                                        ),
                                  ),
                                );
                              }
                            : null,

                        // ================= UPGRADE / EDIT PROFILE =================
                        onUpgradeTap: () {
                          final expert = context.read<ExpertProfileProvider>();
                          final entrepreneur = context
                              .read<EntrepreneurProfileProvider>();
                          final investor = context
                              .read<InvestorProfileProvider>();

                          // 🔥 DETERMINE EFFECTIVE PROFILE TYPE
                          ProfileType effectiveType = ProfileType.normal;

                          if (investor.exists) {
                            effectiveType = ProfileType.investor;
                          } else if (expert.exists) {
                            effectiveType = ProfileType.expert;
                          } else if (entrepreneur.exists) {
                            effectiveType = ProfileType.entrepreneur;
                          }

                          // ================= DRAFT → SUBMIT =================
                          if (effectiveType == ProfileType.expert &&
                              expert.exists &&
                              expert.profile?.applicationStatus == 'draft') {
                            expert.submitForExpertReview();
                            return;
                          }

                          if (effectiveType == ProfileType.entrepreneur &&
                              entrepreneur.exists &&
                              entrepreneur.profile?.applicationStatus ==
                                  'draft') {
                            entrepreneur.submitForEntrepreneurReview();
                            return;
                          }

                          // ================= NAVIGATION =================
                          switch (effectiveType) {
                            case ProfileType.normal:
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (_) => const UpgradeProfileSheet(),
                              );
                              break;

                            case ProfileType.expert:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: expert,
                                    child: const ExpertProfileForm(),
                                  ),
                                ),
                              );
                              break;

                            case ProfileType.entrepreneur:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: entrepreneur,
                                    child: const EntrepreneurProfileForm(),
                                  ),
                                ),
                              );
                              break;

                            case ProfileType.investor:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: investor,
                                    child: const InvestorProfileForm(),
                                  ),
                                ),
                              );
                              break;
                          }
                        },
                      ),
                    ),

                    // ================= STICKY TABS =================
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor:
                              theme.colorScheme.onSurfaceVariant,
                          indicatorColor: theme.colorScheme.primary,
                          tabs: [
                            const Tab(text: 'Posts'),
                            const Tab(text: 'About'),
                            if (!isNormal) const Tab(text: 'Answers'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                // ================= TAB CONTENT (Scrollable Body) =================
                body: TabBarView(
                  children: [
                    PostsTab(posts: provider.posts),
                    const AboutTab(),
                    if (!isNormal) const AnswersTab(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Match background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

//////////////////////////////////////////////////////////////
/// SHIMMER PLACEHOLDER
//////////////////////////////////////////////////////////////

class _ProfileShimmer extends StatelessWidget {
  final ThemeData theme;

  const _ProfileShimmer({required this.theme});

  @override
  Widget build(BuildContext context) {
    final baseColor = theme.colorScheme.surfaceVariant;
    final highlightColor = theme.colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomScrollView(
        slivers: [
          // ===== HEADER SHIMMER =====
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

          // ===== TABS SHIMMER =====
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ===== CONTENT SHIMMER =====
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  height: 90,
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
