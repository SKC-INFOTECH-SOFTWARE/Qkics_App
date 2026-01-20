import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
import 'package:q_kics/booking/payment_page.dart';
import 'package:q_kics/booking/booking_api_service.dart';

class ExpertSlotsPage extends StatefulWidget {
  final String expertUuid;

  const ExpertSlotsPage({super.key, required this.expertUuid});

  @override
  State<ExpertSlotsPage> createState() => _ExpertSlotsPageState();
}

class _ExpertSlotsPageState extends State<ExpertSlotsPage> {
  String? _selectedSlotUuid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bookingProvider = context.read<BookingProvider>();

      // ✅ SET UUID FIRST
      bookingProvider.setExpertUuid(widget.expertUuid);

      // ✅ THEN FETCH
      bookingProvider.fetchSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isAvailable = provider.slots.any((slot) => slot.isAvailable);

    // Auto-select first available slot
    if (_selectedSlotUuid == null && provider.slots.isNotEmpty) {
      final firstAvailable = provider.slots.firstWhere(
        (slot) => slot.isAvailable,
        orElse: () => provider.slots.first,
      );
      _selectedSlotUuid = firstAvailable.uuid;
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
          "Available Slots",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Builder(
        builder: (_) {
          // ================= LOADING =================
          if (provider.isLoading && provider.slots.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // ================= ERROR =================
          if (provider.error != null && provider.slots.isEmpty) {
            return _EmptyState(
              icon: Icons.error_outline,
              title: "Unable to load slots",
              subtitle: provider.error!,
            );
          }

          // ================= EMPTY =================
          if (provider.slots.isEmpty) {
            return const _EmptyState(
              icon: Icons.event_busy,
              title: "No slots available",
              subtitle: "This expert hasn't added any slots yet.",
            );
          }

          // ================= SLOT LIST =================
          return _buildContent(provider, theme, cs);
        },
      ),
      bottomNavigationBar: isAvailable ? _buildBottomBar(provider, theme, cs) : null,
    );
  }

  // ================= MAIN CONTENT =================

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
            "Select a time slot for your appointment",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),

          // SLOT CARDS
          ...provider.slots.map(
            (slot) => _SlotCard(
              slot: slot,
              isSelected: slot.uuid == _selectedSlotUuid,
              onTap: () {
                if (slot.isAvailable) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSlotUuid = slot.uuid);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar(
    BookingProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (provider.slots.isEmpty) return const SizedBox.shrink();

    final selectedSlot = provider.slots.firstWhere(
      (s) => s.uuid == _selectedSlotUuid,
      orElse: () => provider.slots.first,
    );

    final isAvailable = selectedSlot.isAvailable;

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
                  "₹${selectedSlot.price.toStringAsFixed(0)}",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${selectedSlot.durationMinutes} minutes session",
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
              onPressed: isAvailable
                  ? () => _handleBookSlot(selectedSlot)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor: cs.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAvailable
                        ? Icons.calendar_month_outlined
                        : Icons.lock_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                     "Book Slot",
                    style: const TextStyle(
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

  // ================= ACTION =================

  Future<void> _handleBookSlot(ExpertSlot slot) async {
    HapticFeedback.mediumImpact();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create booking first
      final bookingService = BookingApiService();
      final booking = await bookingService.createBooking(slot.uuid);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to payment page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            slot: slot,
            expertName:
                "Expert", // You can pass the actual expert name if available
            bookingId: booking.uuid,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create booking: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print(e);
    }
  }
}

// ===================================================================
// SLOT CARD
// ===================================================================

class _SlotCard extends StatelessWidget {
  final ExpertSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotCard({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isAvailable = slot.isAvailable;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color: isSelected && isAvailable
                ? cs.primary
                : cs.onSurface.withOpacity(0.5),
            width: isSelected && isAvailable ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected && isAvailable
                  ? cs.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected && isAvailable ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
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
                      color: isAvailable
                          ? cs.primary.withOpacity(0.1)
                          : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('dd').format(slot.startDateTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(slot.startDateTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? cs.onSurface
                                : cs.onSurface.withOpacity(0.5),
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
                          DateFormat('EEEE').format(slot.startDateTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${DateFormat.jm().format(slot.startDateTime)}"
                          " - ${DateFormat.jm().format(slot.endDateTime)}",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PRICE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "₹${slot.price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ================= META =================
              Row(
                children: [
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: "${slot.durationMinutes} mins",
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: isAvailable
                        ? Icons.check_circle_outline
                        : Icons.block,
                    label: isAvailable ? "Available" : "Booked",
                    color: isAvailable ? Colors.green : Colors.redAccent,
                  ),

                  // SELECTION INDICATOR
                  const Spacer(),
                  Icon(
                    isSelected && isAvailable
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected && isAvailable
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
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
