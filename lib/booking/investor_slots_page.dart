import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/booking/models/investor_slot.dart';
import 'package:q_kics/booking/booking_api_service.dart';

class InvestorSlotsPage extends StatefulWidget {
  final String investorUuid;
  final String investorName;

  const InvestorSlotsPage({
    super.key,
    required this.investorUuid,
    required this.investorName,
  });

  @override
  State<InvestorSlotsPage> createState() => _InvestorSlotsPageState();
}

class _InvestorSlotsPageState extends State<InvestorSlotsPage> {
  String? _selectedSlotUuid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bookingProvider = context.read<BookingProvider>();
      bookingProvider.setInvestorUuid(widget.investorUuid);
      bookingProvider.fetchInvestorSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Auto-select first slot
    if (_selectedSlotUuid == null && provider.investorSlots.isNotEmpty) {
      _selectedSlotUuid = provider.investorSlots.first.uuid;
    }

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
          "Book with ${widget.investorName}",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Builder(
        builder: (_) {
          if (provider.isLoading && provider.investorSlots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.investorSlots.isEmpty) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: "Unable to load slots",
              subtitle: provider.error!,
            );
          }

          if (provider.investorSlots.isEmpty) {
            return const _EmptyState(
              icon: Icons.event_busy,
              title: "No slots available",
              subtitle: "This investor hasn't added any slots yet.",
            );
          }

          return _buildContent(provider, theme, cs);
        },
      ),
      bottomNavigationBar: provider.investorSlots.isNotEmpty
          ? _buildBottomBar(provider, theme, cs)
          : null,
    );
  }

  Widget _buildContent(
    BookingProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select a time slot to connect with the investor",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          ...provider.investorSlots.map(
            (slot) => _InvestorSlotCard(
              slot: slot,
              isSelected: slot.uuid == _selectedSlotUuid,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedSlotUuid = slot.uuid);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BookingProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (provider.investorSlots.isEmpty) return const SizedBox.shrink();

    final selectedSlot = provider.investorSlots.firstWhere(
      (s) => s.uuid == _selectedSlotUuid,
      orElse: () => provider.investorSlots.first,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                  "${selectedSlot.durationMinutes} min session",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat(
                    "MMM d, yyyy · h:mm a",
                  ).format(selectedSlot.startDateTime.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            width: 160,
            child: ElevatedButton(
              onPressed: () => _handleBookSlot(selectedSlot),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Book Slot",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBookSlot(InvestorSlot slot) async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookingService = BookingApiService();
      await bookingService.createInvestorBooking(slot.uuid);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Booking confirmed with ${widget.investorName}!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Go back to investor list
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create booking: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ===================================================================
// INVESTOR SLOT CARD
// ===================================================================

class _InvestorSlotCard extends StatelessWidget {
  final InvestorSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _InvestorSlotCard({
    required this.slot,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DATE BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd').format(slot.startDateTime.toLocal()),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(slot.startDateTime.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // TIME
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(slot.startDateTime.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${DateFormat.jm().format(slot.startDateTime.toLocal())}"
                        " – ${DateFormat.jm().format(slot.endDateTime.toLocal())}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // SELECTION INDICATOR
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // META ROW
            Row(
              children: [
                _Chip(
                  icon: Icons.timer_outlined,
                  label: "${slot.durationMinutes} mins",
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.handshake_outlined,
                  label: "Available",
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// SMALL UI WIDGETS
//////////////////////////////////////////////////////////////

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.hintColor),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
