import 'package:flutter/material.dart';
import 'package:q_kics/profile/models/public_profile_model.dart';

/// =======================================================
/// PUBLIC USER ABOUT (NORMAL USER)
/// =======================================================
///
/// Shows ONLY data returned by:
/// /api/v1/auth/profiles/<username>/
///
/// Role: "user"
///
class PublicUserAbout extends StatelessWidget {
  final PublicUserProfile profile;

  const PublicUserAbout({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fullName =
        '${profile.firstName} ${profile.lastName}'.trim();

    return Card(
      elevation: theme.brightness == Brightness.dark ? 6 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= NAME =================
            Text(
              fullName.isNotEmpty ? fullName : profile.username,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ================= USERNAME =================
            _row(
              theme,
              'Username',
              '@${profile.username}',
            ),

            // ================= USER TYPE =================
            _row(
              theme,
              'Account Type',
              'Normal User',
            ),
          ],
        ),
      ),
    );
  }

  // ================= INFO ROW =================
  Widget _row(
    ThemeData theme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
