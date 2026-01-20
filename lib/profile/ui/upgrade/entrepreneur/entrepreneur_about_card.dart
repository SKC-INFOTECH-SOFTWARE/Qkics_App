import 'package:flutter/material.dart';

/// Works for:
/// - EntrepreneurProfile (private)
/// - PublicEntrepreneurProfile (public)

class EntrepreneurAboutCard extends StatelessWidget {
  final dynamic profile;
  final bool isPublicView;

  const EntrepreneurAboutCard({
    super.key,
    required this.profile,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String v(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      return value.toString();
    }

    final startupName = v(profile.startupName);
    final oneLiner = v(profile.oneLiner);
    final description = v(profile.description);
    final industry = v(profile.industry);
    final location = v(profile.location);
    final fundingStage = v(profile.fundingStage);
    final website = v(profile.website);

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
            if (startupName.isNotEmpty)
              Text(
                startupName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

            if (oneLiner.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                oneLiner,
                style: theme.textTheme.bodyMedium,
              ),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],

            const SizedBox(height: 16),

            _row(theme, 'Industry', industry),
            _row(theme, 'Location', location),
            _row(theme, 'Funding Stage', fundingStage),

            if (website.isNotEmpty)
              _row(theme, 'Website', website),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

