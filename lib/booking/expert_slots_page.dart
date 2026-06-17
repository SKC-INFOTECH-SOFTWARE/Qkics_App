import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
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
      final p = context.read<BookingProvider>();
      p.setExpertUuid(widget.expertUuid);
      p.fetchSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasAvailable = provider.slots.any((s) => s.isAvailable);

    // Auto-select first available
    if (_selectedSlotUuid == null && provider.slots.isNotEmpty) {
      final first = provider.slots.firstWhere(
        (s) => s.isAvailable,
        orElse: () => provider.slots.first,
      );
      _selectedSlotUuid = first.uuid;
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
          'Available Slots',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Builder(builder: (_) {
        if (provider.isLoading && provider.slots.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.slots.isEmpty) {
          return _EmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load slots',
            subtitle: provider.error!,
          );
        }
        if (provider.slots.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_busy,
            title: 'No slots available',
            subtitle: "This expert hasn't added any slots yet.",
          );
        }
        return _buildContent(provider, theme, cs);
      }),
      bottomNavigationBar: hasAvailable ? _buildBottomBar(provider, theme, cs) : null,
    );
  }

  Widget _buildContent(BookingProvider provider, ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a time slot for your appointment',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
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

  Widget _buildBottomBar(BookingProvider provider, ThemeData theme, ColorScheme cs) {
    if (provider.slots.isEmpty) return const SizedBox.shrink();
    final selectedSlot = provider.slots.firstWhere(
      (s) => s.uuid == _selectedSlotUuid,
      orElse: () => provider.slots.first,
    );
    final canBook = selectedSlot.isAvailable;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedSlot.isChatAvailable)
                  Text(
                    'Chat ₹${selectedSlot.chatPrice.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (selectedSlot.isVideoCallAvailable)
                  Text(
                    'Video ₹${selectedSlot.videoCallPrice.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  '${selectedSlot.durationMinutes} min session',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 54,
            width: 160,
            child: ElevatedButton(
              onPressed: canBook ? () => _handleBookSlot(selectedSlot) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                disabledBackgroundColor: cs.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canBook ? Icons.calendar_month_outlined : Icons.lock_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Book Slot',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBookSlot(ExpertSlot slot) async {
    HapticFeedback.mediumImpact();

    // Ask user to choose session type (only show available options)
    final sessionType = await _showSessionTypePicker(slot);
    if (sessionType == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookingService = BookingApiService();
      final booking = await bookingService.createBooking(slot.uuid, sessionType);
      await bookingService.createBookingPayment(booking.uuid);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      setState(() => _selectedSlotUuid = null);
      context.read<BookingProvider>().fetchSlots();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shows a bottom sheet to choose CHAT or VIDEO_CALL.
  /// Returns null if the user cancels.
  Future<String?> _showSessionTypePicker(ExpertSlot slot) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Session Type',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(slot.startDateTime),
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 20),
                if (slot.isChatAvailable)
                  _SessionTypeOption(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat Session',
                    price: '₹${slot.chatPrice.toStringAsFixed(0)}',
                    color: Colors.blue,
                    onTap: () => Navigator.pop(ctx, 'CHAT'),
                  ),
                if (slot.isChatAvailable && slot.isVideoCallAvailable)
                  const SizedBox(height: 12),
                if (slot.isVideoCallAvailable)
                  _SessionTypeOption(
                    icon: Icons.videocam_outlined,
                    label: 'Video Call Session',
                    price: '₹${slot.videoCallPrice.toStringAsFixed(0)}',
                    color: Colors.green,
                    onTap: () => Navigator.pop(ctx, 'VIDEO_CALL'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session type option tile
// ─────────────────────────────────────────────────────────────────────────────
class _SessionTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String price;
  final Color color;
  final VoidCallback onTap;

  const _SessionTypeOption({
    required this.icon,
    required this.label,
    required this.price,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ),
            Text(
              price,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot card
// ─────────────────────────────────────────────────────────────────────────────
class _SlotCard extends StatelessWidget {
  final ExpertSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SlotCard({required this.slot, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final available = slot.isAvailable;

    return GestureDetector(
      onTap: available ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          border: Border.all(
            color: isSelected && available ? cs.primary : cs.onSurface.withValues(alpha: 0.15),
            width: isSelected && available ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected && available
                  ? cs.primary.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected && available ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Opacity(
          opacity: available ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: available ? cs.primary.withValues(alpha: 0.1) : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('dd').format(slot.startDateTime),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: available ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(slot.startDateTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: available ? cs.onSurface : cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(slot.startDateTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat.jm().format(slot.startDateTime)} — '
                          '${DateFormat.jm().format(slot.endDateTime)}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        // Pricing row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (slot.isChatAvailable)
                              _PricePill(
                                icon: Icons.chat_bubble_outline,
                                label: '₹${slot.chatPrice.toStringAsFixed(0)}',
                                color: Colors.blue,
                              ),
                            if (slot.isVideoCallAvailable)
                              _PricePill(
                                icon: Icons.videocam_outlined,
                                label: '₹${slot.videoCallPrice.toStringAsFixed(0)}',
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: '${slot.durationMinutes} mins',
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: available ? Icons.check_circle_outline : Icons.block,
                    label: slot.isBooked ? 'Booked' : 'Available',
                    color: available ? Colors.green : Colors.redAccent,
                  ),
                  const Spacer(),
                  Icon(
                    isSelected && available
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isSelected && available ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
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

class _PricePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PricePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

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
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: color),
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
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

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
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
