import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/profile/models/public_profile_model.dart';

import 'package:q_kics/profile/ui/upgrade/expert/certification_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/education_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/experience_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/expert_status_badge.dart';
import 'package:q_kics/profile/ui/upgrade/expert/honor_section.dart';
import 'package:q_kics/profile/ui/upgrade/profile_completion_card.dart';

import 'package:q_kics/profile/ui/upgrade/entrepreneur/entrepreneur_about_card.dart';
import 'package:q_kics/profile/ui/upgrade/investor/investor_about_card.dart';

import 'package:q_kics/profile/utils/profile_completion_utils.dart';

import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';
import 'package:q_kics/providers/investor_profile_provider.dart';

class AboutTab extends StatelessWidget {
  /// 🔒 Public / Private mode
  final bool isPublicView;

  /// 🌍 Public base user profile
  final UserProfile? publicProfile;

  /// 🌍 Public role profile (expert / entrepreneur / investor)
  final dynamic publicRoleProfile;

  const AboutTab({
    super.key,
    this.isPublicView = false,
    this.publicProfile,
    this.publicRoleProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ======================================================
    // RESOLVE BASE PROFILE
    // ======================================================
    late final UserProfile profile;

    if (isPublicView) {
      if (publicProfile == null) {
        return const Center(child: Text('Public profile data not available'));
      }
      profile = publicProfile!;
    } else {
      final profileProvider = context.watch<ProfileProvider>();
      profile = profileProvider.profile!;
    }

    // ======================================================
    // ROLE FLAGS
    // ======================================================
    final bool isExpert = profile.userType == 'expert';
    final bool isEntrepreneur = profile.userType == 'entrepreneur';
    final bool isInvestor = profile.userType == 'investor';

    // ======================================================
    // PRIVATE PROVIDERS (PRIVATE MODE ONLY)
    // ======================================================
    final expertProvider = !isPublicView && isExpert
        ? context.watch<ExpertProfileProvider>()
        : null;

    final entrepreneurProvider = !isPublicView && isEntrepreneur
        ? context.watch<EntrepreneurProfileProvider>()
        : null;

    final investorProvider = !isPublicView && isInvestor
        ? context.watch<InvestorProfileProvider>()
        : null;

    String displayName() {
      final first = profile.firstName?.trim() ?? '';
      final last = profile.lastName?.trim() ?? '';
      if (first.isNotEmpty || last.isNotEmpty) {
        return '$first $last'.trim();
      }
      return profile.username;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ==================================================
        // BASIC INFO
        // ==================================================
        _info(context, 'Name', displayName()),

        if (!isPublicView) ...[
          _info(context, 'Email', profile.email),
          _info(context, 'Phone', profile.phone),
        ],

        _info(context, 'Account Type', profile.userType.toUpperCase()),

        // ==================================================
        // ENTREPRENEUR ABOUT
        // ==================================================
        if (isEntrepreneur) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Startup',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          EntrepreneurAboutCard(
            profile: isPublicView
                ? publicRoleProfile as PublicEntrepreneurProfile
                : entrepreneurProvider!.profile!,
            isPublicView: isPublicView,
          ),
        ],

        // ==================================================
        // INVESTOR ABOUT
        // ==================================================
        if (isInvestor) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Investor',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          InvestorAboutCard(
            profile: isPublicView
                ? publicRoleProfile as PublicInvestorProfile
                : investorProvider!.profile!,
            isPublicView: isPublicView,
          ),
        ],

        // ==================================================
        // EXPERT ABOUT (PUBLIC + PRIVATE)
        // ==================================================
        if (isExpert) ...[
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // ---------- PRIVATE STATUS ----------
          if (!isPublicView)
            ExpertStatusBadge(
              verified: expertProvider!.profile!.verified,
              status: expertProvider.profile!.applicationStatus,
              adminNote: expertProvider.profile!.adminReviewNote,
            ),

          if (!isPublicView) const SizedBox(height: 10),

          // ---------- BASIC DETAILS ----------
          ExpertAboutCard(
            profile: isPublicView
                ? publicRoleProfile as PublicExpertProfile
                : expertProvider!.profile!,
          ),

          // ---------- PRIVATE ONLY ----------
          if (!isPublicView) ...[
            const SizedBox(height: 10),
            ProfileCompletionCard(
              progress: calculateExpertCompletion(
                hasHeadline: expertProvider!.profile!.headline.isNotEmpty,
                hasExperience: expertProvider.experiences.isNotEmpty,
                hasEducation: expertProvider.educations.isNotEmpty,
                hasCertification: expertProvider.certifications.isNotEmpty,
                hasHonor: expertProvider.honors.isNotEmpty,
              ),
              suggestions: [
                if (expertProvider.profile!.headline.isEmpty)
                  'Add a professional headline',
                if (expertProvider.experiences.isEmpty) 'Add work experience',
                if (expertProvider.educations.isEmpty) 'Add education',
                if (expertProvider.certifications.isEmpty) 'Add certifications',
                if (expertProvider.honors.isEmpty) 'Add honors or awards',
              ],
            ),
          ],

          const SizedBox(height: 10),

          // ---------- PORTFOLIO ----------
          Text(
            'Expert Portfolio',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (isPublicView) ...[
            ExperienceSection(
              isPublicView: true,
              publicExperiences: List<Map<String, dynamic>>.from(
                (publicRoleProfile as PublicExpertProfile).experiences,
              ),
            ),
            EducationSection(
              isPublicView: true,
              publicEducations: List<Map<String, dynamic>>.from(
                (publicRoleProfile as PublicExpertProfile).educations,
              ),
            ),
            CertificationSection(
              isPublicView: true,
              publicCertifications: List<Map<String, dynamic>>.from(
                (publicRoleProfile as PublicExpertProfile).certifications,
              ),
            ),
            HonorSection(
              isPublicView: true,
              publicHonors: List<Map<String, dynamic>>.from(
                (publicRoleProfile as PublicExpertProfile).honorsAwards,
              ),
            ),
          ] else ...[
            const ExperienceSection(),
            const EducationSection(),
            const CertificationSection(),
            const HonorSection(),
          ],
        ],
      ],
    );
  }

  // ======================================================
  // INFO ROW
  // ======================================================
  Widget _info(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// EXPERT BASIC DETAILS CARD (UNCHANGED)
////////////////////////////////////////////////////////////

class ExpertAboutCard extends StatelessWidget {
  final dynamic profile;

  const ExpertAboutCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: theme.brightness == Brightness.dark ? 6 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((profile.headline ?? '').isNotEmpty)
              Text(
                profile.headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            _row(theme, 'Primary Expertise', profile.primaryExpertise),
            if ((profile.otherExpertise ?? '').isNotEmpty)
              _row(theme, 'Other Expertise', profile.otherExpertise),
            _row(theme, 'Hourly Rate', '₹${profile.hourlyRate}/hr'),
            _row(
              theme,
              'Availability',
              profile.isAvailable ? 'Available' : 'Not Available',
              valueColor: profile.isAvailable ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
