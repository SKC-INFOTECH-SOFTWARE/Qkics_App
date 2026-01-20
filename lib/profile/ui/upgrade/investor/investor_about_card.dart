import 'package:flutter/material.dart';

class InvestorAboutCard extends StatelessWidget {
  /// Can be:
  /// - InvestorProfile (private)
  /// - PublicInvestorProfile (public)
  final dynamic profile;

  final bool isPublicView;

  const InvestorAboutCard({
    super.key,
    required this.profile,
    this.isPublicView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (profile == null) {
      return const Text('Investor profile not available');
    }

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
            // ==================================================
            // DISPLAY NAME
            // ==================================================
            if ((profile.displayName ?? '').toString().isNotEmpty)
              Text(
                profile.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

            // ==================================================
            // ONE LINER
            // ==================================================
            if ((profile.oneLiner ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                profile.oneLiner,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ==================================================
            // INVESTOR TYPE
            // ==================================================
            _row(
              theme,
              'Investor Type',
              profile.investorTypeDisplay ??
                  profile.investorType?.toString().toUpperCase(),
            ),

            // ==================================================
            // CHECK SIZE
            // ==================================================
            _row(
              theme,
              'Check Size',
              _checkSizeText(
                profile.checkSizeMin,
                profile.checkSizeMax,
              ),
            ),

            // ==================================================
            // LOCATION
            // ==================================================
            if ((profile.location ?? '').toString().isNotEmpty)
              _row(theme, 'Location', profile.location),

            const SizedBox(height: 12),

            // ==================================================
            // FOCUS INDUSTRIES
            // ==================================================
            if ((profile.focusIndustries ?? []).isNotEmpty) ...[
              Text(
                'Focus Industries',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _chipWrap(
                context,
                List<String>.from(
                  profile.focusIndustries
                      .map((e) => e.name.toString()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ==================================================
            // PREFERRED STAGES
            // ==================================================
            if ((profile.preferredStages ?? []).isNotEmpty) ...[
              Text(
                'Preferred Stages',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _chipWrap(
                context,
                List<String>.from(
                  profile.preferredStages
                      .map((e) => e.name.toString()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ==================================================
            // INVESTMENT THESIS
            // ==================================================
            if ((profile.investmentThesis ?? '').toString().isNotEmpty) ...[
              Text(
                'Investment Thesis',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.investmentThesis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // ==================================================
            // LINKS
            // ==================================================
            if (_hasAnyLink(profile)) ...[
              const Divider(),
              const SizedBox(height: 8),
              _links(context),
            ],

            // ==================================================
            // VERIFIED BADGE (PRIVATE VIEW)
            // ==================================================
            if (!isPublicView && profile.verifiedByAdmin == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Verified Investor',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ======================================================
  // HELPERS
  // ======================================================

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipWrap(BuildContext context, List<String> values) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (v) => Chip(
              label: Text(v),
              backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.08),
            ),
          )
          .toList(),
    );
  }

  String _checkSizeText(dynamic min, dynamic max) {
    try {
      final minVal = double.parse(min.toString()).toInt();
      final maxVal = double.parse(max.toString()).toInt();
      return '₹${_format(minVal)} – ₹${_format(maxVal)}';
    } catch (_) {
      return 'Not specified';
    }
  }

  String _format(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  bool _hasAnyLink(dynamic p) {
    return (p.websiteUrl ?? '').toString().isNotEmpty ||
        (p.linkedinUrl ?? '').toString().isNotEmpty ||
        (p.twitterUrl ?? '').toString().isNotEmpty;
  }

  Widget _links(BuildContext context) {
    final theme = Theme.of(context);

    Widget link(String label, String? url, IconData icon) {
      if (url == null || url.isEmpty) return const SizedBox();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        link('Website', profile.websiteUrl, Icons.language),
        link('LinkedIn', profile.linkedinUrl, Icons.business),
        link('Twitter', profile.twitterUrl, Icons.alternate_email),
      ],
    );
  }
}
