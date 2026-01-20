import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/subscription_provider.dart';
import '../models/subscription_plan.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  String? _selectedPlanUuid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_selectedPlanUuid == null && provider.plans.isNotEmpty) {
      _selectedPlanUuid = provider.plans.first.uuid;
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Choose Your Plan",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
           
          ),
        ),
      ),
      body: provider.isLoading && provider.plans.isEmpty
          ? _buildLoading()
          : provider.error != null && provider.plans.isEmpty
              ? _buildError(provider)
              : _buildContent(provider, theme, cs),
      bottomNavigationBar: _buildBottomBar(provider, theme, cs),
    );
  }

  // ================= LOADING =================

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  // ================= ERROR =================

  Widget _buildError(SubscriptionProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          const Text("Failed to load subscription plans"),
          TextButton(
            onPressed: provider.fetchPlans,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  // ================= MAIN CONTENT =================

  Widget _buildContent(
    SubscriptionProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pick a plan that suits your needs",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),

          // PLAN CARDS
          ...provider.plans.map(
            (plan) => _PlanCard(
              plan: plan,
              isSelected: plan.uuid == _selectedPlanUuid,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPlanUuid = plan.uuid);
              },
            ),
          ),

          const SizedBox(height: 40),

          // COMPARE TABLE
          _buildComparePlans(provider.plans, theme, cs),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar(
    SubscriptionProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (provider.plans.isEmpty) return const SizedBox.shrink();

    final plan = provider.plans.firstWhere(
      (p) => p.uuid == _selectedPlanUuid,
      orElse: () => provider.plans.first,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₹${plan.price}",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${plan.durationDays} days access",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            width: 160,
            child: ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _handleSubscribe(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Continue",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ACTION =================

  Future<void> _handleSubscribe(SubscriptionPlan plan) async {
    final provider = context.read<SubscriptionProvider>();
    HapticFeedback.mediumImpact();

    final success = await provider.subscribe(plan.uuid);
    if (!mounted) return;

    if (success) {
      _showSuccess(plan.name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? "Something went wrong")),
      );
    }
  }

  void _showSuccess(String planName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Subscription Activated"),
        content: Text("You are now subscribed to $planName."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Profile"),
          ),
        ],
      ),
    );
  }

  // ================= COMPARE TABLE =================

  Widget _buildComparePlans(
    List<SubscriptionPlan> plans,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (plans.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compare plans",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.5)),
            ),
            child: DataTable(
              columnSpacing: 28,
              headingRowHeight: 50,
              dataRowHeight: 54,
              headingTextStyle: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              columns: [
                const DataColumn(label: Text("Features")),
                ...plans.map(
                  (p) => DataColumn(
                    label: Text(
                      p.name,
                      style: TextStyle(color: cs.primary),
                    ),
                  ),
                ),
              ],
              rows: [
                _row("Price", plans.map((p) => "₹${p.price}").toList()),
                _row(
                  "Duration",
                  plans.map((p) => "${p.durationDays} days").toList(),
                ),
                _row(
                  "Premium Docs / month",
                  plans.map((p) => p.premiumDocLimit.toString()).toList(),
                ),
                _row(
                  "Free Chats / month",
                  plans.map((p) => p.freeChatPerMonth.toString()).toList(),
                ),
                _row(
                  "Free Consultations",
                  plans.map((p) => p.freeConsultationCount.toString()).toList(),
                ),
                DataRow(
                  cells: [
                    const DataCell(Text("Active")),
                    ...plans.map(
                      (p) => DataCell(
                        Icon(
                          p.isActive
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          size: 18,
                          color:
                              p.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(String title, List<String> values) {
    return DataRow(
      cells: [
        DataCell(Text(title)),
        ...values.map((v) => DataCell(Text(v))).toList(),
      ],
    );
  }
}

// ===================================================================
// PLAN CARD
// ===================================================================

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color:
                isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? cs.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (plan.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "ACTIVE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              "₹${plan.price}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green, 
              ),
            ),
            Text(
              "Valid for ${plan.durationDays} days",
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            _feature(
              Icons.description_outlined,
              "${plan.premiumDocLimit} Premium Documents / month",
            ),
            _feature(
              Icons.chat_bubble_outline,
              "${plan.freeChatPerMonth} Free Chats / month",
            ),
            _feature(
              Icons.medical_services_outlined,
              "${plan.freeConsultationCount} Free Consultations",
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? cs.primary : cs.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
