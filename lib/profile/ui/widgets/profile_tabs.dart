import 'package:flutter/material.dart';
import 'package:q_kics/profile/models/profile_type.dart';
import 'package:q_kics/profile/ui/widgets/about_tab.dart';
import 'package:q_kics/profile/ui/widgets/answers_tab.dart';
import 'package:q_kics/profile/ui/widgets/posts_tab.dart';
import 'package:q_kics/providers/profile_provider.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileProvider provider;

  const ProfileTabs({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // ✅ Determine tab count ONCE
    final isNormal = provider.profileType == ProfileType.normal;
    final tabCount = isNormal ? 2 : 3;

    return DefaultTabController(
      length: tabCount,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Posts'),
              const Tab(text: 'About'),
              if (!isNormal) const Tab(text: 'Answers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                PostsTab(posts: provider.posts),
                const AboutTab(),
                if (!isNormal) const AnswersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
