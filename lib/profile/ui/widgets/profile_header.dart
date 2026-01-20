// profile_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/profile/models/profile_type.dart';

import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';
import 'package:q_kics/providers/investor_profile_provider.dart';

import 'package:q_kics/profile/ui/upgrade/edit_profile_sheet.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/subscriptions/providers/subscription_provider.dart';
import 'package:q_kics/subscriptions/ui/subscription_plans_page.dart';
import 'package:q_kics/subscriptions/ui/active_subscription_page.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onUpgradeTap;

  final bool isPublicView;
  final VoidCallback? onViewSlotsTap;
  final VoidCallback? onCreateSlotsTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onUpgradeTap,
    this.onViewSlotsTap,
    this.onCreateSlotsTap,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ======================================================
    // PROVIDERS (PRIVATE ONLY)
    // ======================================================
    final expertProvider = !isPublicView
        ? context.watch<ExpertProfileProvider>()
        : null;
    final entrepreneurProvider = !isPublicView
        ? context.watch<EntrepreneurProfileProvider>()
        : null;
    final investorProvider = !isPublicView
        ? context.watch<InvestorProfileProvider>()
        : null;
    final subscriptionProvider = !isPublicView
        ? context.watch<SubscriptionProvider>()
        : null;

    // ======================================================
    // 🔥 DETERMINE EFFECTIVE PROFILE TYPE
    // ======================================================
    ProfileType effectiveType = ProfileType.normal;

    if (!isPublicView && investorProvider?.exists == true) {
      effectiveType = ProfileType.investor;
    } else if (!isPublicView && expertProvider?.exists == true) {
      effectiveType = ProfileType.expert;
    } else if (!isPublicView && entrepreneurProvider?.exists == true) {
      effectiveType = ProfileType.entrepreneur;
    } else {
      effectiveType = ProfileType.fromString(profile.userType);
    }

    // ======================================================
    // DRAFT / PENDING (ONLY FOR EXPERT & ENTREPRENEUR)
    // ======================================================
    final bool hasDraft =
        !isPublicView &&
        ((expertProvider?.hasDraft ?? false) ||
            (entrepreneurProvider?.hasDraft ?? false));

    final bool isPending =
        !isPublicView &&
        ((expertProvider?.isPending ?? false) ||
            (entrepreneurProvider?.isPending ?? false));

    // ======================================================
    // PROFILE IMAGE
    // ======================================================
    final hasImage =
        profile.profilePicture != null && profile.profilePicture!.isNotEmpty;

    final String displayImageUrl = hasImage
        ? isPublicView
              ? profile.profilePicture!
              : '${profile.profilePicture}?t=${profile.hashCode}'
        : '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surfaceVariant.withOpacity(0.3),
            theme.scaffoldBackgroundColor,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= AVATAR =================
                GestureDetector(
                  onTap: isPublicView ? null : () => _openEditSheet(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Gradient Border Effect
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3), // Border width
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.scaffoldBackgroundColor,
                      ),
                      padding: const EdgeInsets.all(
                        3,
                      ), // Whitespace between border and image
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: hasImage
                            ? NetworkImage(displayImageUrl)
                            : null,
                        child: !hasImage
                            ? Text(
                                profile.initial,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // ================= INFO =================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // ---------- NAME ----------
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                fontSize: 22,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (!isPublicView)
                            IconButton(
                              onPressed: () => _openEditSheet(context),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              tooltip: "Edit Profile",
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ---------- USERNAME + BADGE ----------
                      Row(
                        children: [
                          Text(
                            '@${profile.username}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // _userTypeBadge(theme, effectiveType),
                          // if (!isPublicView &&
                          //     subscriptionProvider?.activeSubscription !=
                          //         null) ...[
                          //   const SizedBox(width: 8),
                          //   _premiumBadge(theme),
                          //],
                        ],
                      ),

                      const SizedBox(height: 12),
                      if (!isPublicView)
                      _getPremiumButton(context, theme),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= ACTIONS ROW =================
            if (!isPublicView && (onUpgradeTap != null || isPending))
              _buildActionButtons(
                context,
                effectiveType,
                hasDraft,
                isPending,
                colorScheme,
              ),

            // ================= PUBLIC VIEW ACTIONS =================
            if (isPublicView && effectiveType == ProfileType.expert)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onViewSlotsTap,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text("Book Appointment"),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

            // ================= PENDING STATUS =================
            if (!isPublicView && isPending) ...[
              const SizedBox(height: 16),
              _pendingBadge(theme),
            ],
          ],
        ),
      ),
    );
  }

  // ======================================================
  // HELPERS
  // ======================================================

  Widget _buildActionButtons(
    BuildContext context,
    ProfileType type,
    bool hasDraft,
    bool isPending,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        if (onUpgradeTap != null)
          Expanded(
            child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: isPending ? null : onUpgradeTap,
                icon: Icon(_buttonIcon(type, hasDraft), size: 18),
                label: Text(
                  _buttonLabel(type, hasDraft, isPending),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),

        if (type == ProfileType.expert) ...[
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onCreateSlotsTap,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text("Slots"),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _userTypeBadge(ThemeData theme, ProfileType type) {
    Color badgeColor;
    Color textColor;

    switch (type) {
      case ProfileType.expert:
        badgeColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case ProfileType.entrepreneur:
        badgeColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case ProfileType.investor:
        badgeColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        break;
      default:
        badgeColor = theme.colorScheme.surfaceVariant;
        textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _buttonLabel(ProfileType type, bool hasDraft, bool isPending) {
    if (isPending) return 'Review Pending';
    if (type == ProfileType.normal && hasDraft) return 'Resume';
    switch (type) {
      case ProfileType.normal:
        return 'Upgrade';
      case ProfileType.expert:
      case ProfileType.entrepreneur:
      case ProfileType.investor:
        return 'Edit Profile';
    }
  }

  IconData _buttonIcon(ProfileType type, bool hasDraft) {
    if (type == ProfileType.normal && !hasDraft)
      return Icons.rocket_launch_outlined;
    if (hasDraft) return Icons.save_as_outlined;
    return Icons.edit_note_outlined;
  }

  Widget _pendingBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 20,
            color: Colors.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Under Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
                Text(
                  'Your application is currently being reviewed by admins.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[900]?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditbasicProfileSheet(profile: profile),
    );

    if (context.mounted) {
      await context.read<ProfileProvider>().loadProfile(force: true);
    }
  }

  Widget _premiumBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[700]!, Colors.orange[800]!],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: 10),
          SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPremiumButton(BuildContext context, ThemeData theme) {
    final subscriptionProvider = !isPublicView
        ? context.watch<SubscriptionProvider>()
        : null;

    final hasActiveSubscription =
        subscriptionProvider?.activeSubscription != null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => hasActiveSubscription
                ? const ActiveSubscriptionPage()
                : const SubscriptionPlansPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasActiveSubscription
              ? Colors.green.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveSubscription
                ? Colors.green.withOpacity(0.2)
                : theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          
          children: [
            Icon(
              hasActiveSubscription
                  ? Icons.card_membership_rounded
                  : Icons.rocket_launch_rounded,
              size: 14,
              color: hasActiveSubscription
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            
            Text(
              hasActiveSubscription ? "My Subscription" : "Upgrade to Premium",
              style: TextStyle(
                color: hasActiveSubscription
                    ? Colors.green
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: hasActiveSubscription
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
