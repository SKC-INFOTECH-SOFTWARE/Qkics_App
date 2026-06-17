import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/booking/expert_slots_page.dart';
import 'package:q_kics/booking/models/expert_model.dart';
import 'package:q_kics/providers/booking_provider.dart';

class BookingExpertsPage extends StatefulWidget {
  const BookingExpertsPage({super.key});

  @override
  State<BookingExpertsPage> createState() => _BookingExpertsPageState();
}

class _BookingExpertsPageState extends State<BookingExpertsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchExperts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text(
          "Book an Expert",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          if (provider.experts.isEmpty) {
            return const Center(child: Text("No experts available"));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 700;

              /// 📱 Phone
              if (!isTablet) {
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.experts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ExpertHorizontalCard(expert: provider.experts[i]),
                );
              }

              /// 💻 Tablet → 3 cards per row
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.6,
                ),
                itemCount: provider.experts.length,
                itemBuilder: (_, i) =>
                    _ExpertHorizontalCard(expert: provider.experts[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExpertHorizontalCard extends StatelessWidget {
  final ExpertModel expert;

  const _ExpertHorizontalCard({required this.expert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      elevation: 6, // ⬅️ STRONGER ELEVATION
      shadowColor: cs.primary.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25), // ⬅️ COLORED BORDER
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: expert.isAvailable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExpertSlotsPage(
                            expertUuid: expert.expertUuid,
                          ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                /// Avatar + availability
                Stack(
                  children: [
                    _Avatar(
                      imageUrl: expert.profilePicture,
                      name: expert.name,
                      size: 64,
                    ),
                    if (expert.isAvailable)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                /// Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              expert.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (expert.verified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 14,
                                color: Color(0xFFE53935),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expert.primaryExpertise,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expert.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.25,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                /// Price
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "₹${expert.hourlyRate.round()}/hr",
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const _Avatar({
    required this.name,
    this.imageUrl,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _Fallback(name: name),
              )
            : _Fallback(name: name),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String name;

  const _Fallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "?",
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
