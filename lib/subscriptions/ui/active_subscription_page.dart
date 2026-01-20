import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../providers/subscription_provider.dart';
import '../models/active_subscription.dart';
import 'subscription_plans_page.dart';

class ActiveSubscriptionPage extends StatefulWidget {
  const ActiveSubscriptionPage({super.key});

  @override
  State<ActiveSubscriptionPage> createState() => _ActiveSubscriptionPageState();
}

class _ActiveSubscriptionPageState extends State<ActiveSubscriptionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchActiveSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Subscription",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: provider.isLoading && provider.activeSubscription == null
          ? _buildLoading(theme, cs)
          : provider.activeSubscription == null
          ? _buildNoSubscription(theme, cs)
          : _buildContent(provider.activeSubscription!, theme, cs),
    );
  }

  // ================= LOADING =================

  Widget _buildLoading(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: cs.surfaceVariant,
            highlightColor: cs.surface,
            child: Column(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= NO SUBSCRIPTION =================

  Widget _buildNoSubscription(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_membership_outlined,
                size: 64,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Active Subscription",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Subscribe to a plan to unlock premium features and benefits",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPlansPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Browse Plans",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MAIN CONTENT =================

  Widget _buildContent(
    ActiveSubscription subscription,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final daysRemaining = subscription.endDate
        .difference(DateTime.now())
        .inDays;
    final totalDays = subscription.endDate
        .difference(subscription.startDate)
        .inDays;
    final progress = (totalDays - daysRemaining) / totalDays;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<SubscriptionProvider>().fetchActiveSubscription();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= SUBSCRIPTION STATUS CARD =================
            _buildStatusCard(subscription, daysRemaining, progress, theme, cs),

            const SizedBox(height: 20),

            // ================= USAGE STATISTICS =================
            _buildUsageSection(subscription, theme, cs),

            const SizedBox(height: 20),

            // ================= PLAN DETAILS =================
            _buildPlanDetails(subscription, theme, cs),

            const SizedBox(height: 20),

            // ================= SUBSCRIPTION INFO =================
            _buildSubscriptionInfo(subscription, theme, cs),

            const SizedBox(height: 32),

            // ================= UPGRADE BUTTON =================
            _buildUpgradeButton(theme, cs),
          ],
        ),
      ),
    );
  }

  // ================= STATUS CARD =================

  Widget _buildStatusCard(
    ActiveSubscription subscription,
    int daysRemaining,
    double progress,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final isExpiringSoon = daysRemaining <= 7;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        border: Border.all(
          color: isExpiringSoon
              ? Colors.orange.withOpacity(0.5)
              : cs.primary.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isExpiringSoon ? Colors.orange : cs.primary).withOpacity(
              0.1,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.plan.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: subscription.isActive
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subscription.isActive ? "Active" : "Inactive",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subscription.isActive
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "₹${subscription.plan.price}",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$daysRemaining days remaining",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}% used",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: cs.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isExpiringSoon ? Colors.orange : cs.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Expiry Date
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpiringSoon
                  ? Colors.orange.withOpacity(0.1)
                  : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isExpiringSoon
                      ? Icons.warning_amber_rounded
                      : Icons.calendar_today_rounded,
                  size: 18,
                  color: isExpiringSoon ? Colors.orange : cs.onSurface,
                ),
                const SizedBox(width: 10),
                Text(
                  isExpiringSoon
                      ? "Expires soon on ${DateFormat('MMM dd, yyyy').format(subscription.endDate)}"
                      : "Valid until ${DateFormat('MMM dd, yyyy').format(subscription.endDate)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isExpiringSoon
                        ? Colors.orange
                        : cs.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= USAGE SECTION =================

  Widget _buildUsageSection(
    ActiveSubscription subscription,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Usage This Month",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _UsageCard(
                icon: Icons.description_outlined,
                title: "Premium Docs",
                used: subscription.premiumDocsUsedThisMonth,
                total: subscription.plan.premiumDocLimit,
                color: Colors.blue,
                theme: theme,
                cs: cs,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UsageCard(
                icon: Icons.chat_bubble_outline,
                title: "Free Chats",
                used: subscription.chatsUsedThisMonth,
                total: subscription.plan.freeChatPerMonth,
                color: Colors.purple,
                theme: theme,
                cs: cs,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ConsultationCard(
          used: subscription.freeConsultationUsed,
          total: subscription.plan.freeConsultationCount,
          theme: theme,
          cs: cs,
        ),
      ],
    );
  }

  // ================= PLAN DETAILS =================

  Widget _buildPlanDetails(
    ActiveSubscription subscription,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plan Benefits",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _BenefitRow(
            icon: Icons.description_outlined,
            text:
                "${subscription.plan.premiumDocLimit} Premium Documents per month",
            theme: theme,
            cs: cs,
          ),
          _BenefitRow(
            icon: Icons.chat_bubble_outline,
            text: "${subscription.plan.freeChatPerMonth} Free Chats per month",
            theme: theme,
            cs: cs,
          ),
          _BenefitRow(
            icon: Icons.medical_services_outlined,
            text:
                "${subscription.plan.freeConsultationCount} Free Consultations",
            theme: theme,
            cs: cs,
          ),
          _BenefitRow(
            icon: Icons.access_time_rounded,
            text: "${subscription.plan.durationDays} days validity",
            theme: theme,
            cs: cs,
          ),
        ],
      ),
    );
  }

  // ================= SUBSCRIPTION INFO =================

  Widget _buildSubscriptionInfo(
    ActiveSubscription subscription,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: "Subscribed On",
            value: DateFormat('MMM dd, yyyy').format(subscription.startDate),
            theme: theme,
            cs: cs,
          ),
          const Divider(height: 24),
          _InfoRow(
            label: "Renewal Date",
            value: DateFormat('MMM dd, yyyy').format(subscription.endDate),
            theme: theme,
            cs: cs,
          ),
          const Divider(height: 24),
          _InfoRow(
            label: "Plan Duration",
            value: "${subscription.plan.durationDays} days",
            theme: theme,
            cs: cs,
          ),
        ],
      ),
    );
  }

  // ================= UPGRADE BUTTON =================

  Widget _buildUpgradeButton(ThemeData theme, ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "Upgrade or Change Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// USAGE CARD
// ===================================================================

class _UsageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int used;
  final int total;
  final Color color;
  final ThemeData theme;
  final ColorScheme cs;

  const _UsageCard({
    required this.icon,
    required this.title,
    required this.used,
    required this.total,
    required this.color,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$used / $total",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: cs.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CONSULTATION CARD
// ===================================================================

class _ConsultationCard extends StatelessWidget {
  final bool used;
  final int total;
  final ThemeData theme;
  final ColorScheme cs;

  const _ConsultationCard({
    required this.used,
    required this.total,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Free Consultations",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  used ? "Used" : "Available",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: used ? cs.surfaceVariant : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              used ? "0 / $total" : "$total Available",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: used ? cs.onSurface.withOpacity(0.6) : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// BENEFIT ROW
// ===================================================================

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;
  final ColorScheme cs;

  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          Icon(Icons.check_circle, size: 18, color: Colors.green),
        ],
      ),
    );
  }
}

// ===================================================================
// INFO ROW
// ===================================================================

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme cs;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
