import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/booking_provider.dart';
import '../booking/models/booking.dart';

class UserBookingsPage extends StatefulWidget {
  const UserBookingsPage({super.key});

  @override
  State<UserBookingsPage> createState() => _UserBookingsPageState();
}

class _UserBookingsPageState extends State<UserBookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
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
          "My Bookings",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: provider.isLoadingBookings
          ? _buildLoading()
          : provider.bookingsError != null
          ? _buildError(provider)
          : _buildContent(provider, theme, cs),
    );
  }

  // ================= LOADING =================

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ================= ERROR =================

  Widget _buildError(BookingProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(provider.bookingsError ?? "Failed to load bookings"),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => provider.fetchUserBookings(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent(
    BookingProvider provider,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (provider.userBookings.isEmpty) {
      return _buildEmptyState(theme, cs);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: provider.userBookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: provider.userBookings[index]);
      },
    );
  }

  // ================= EMPTY STATE =================

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: cs.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No bookings yet",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Book an expert to get started",
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// BOOKING CARD
// ===================================================================

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Name + Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.expertName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Expert",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // DATE & TIME
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: "Date & Time",
            value: _formatDateTime(booking.startDatetime),
          ),

          const SizedBox(height: 12),

          // DURATION
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: "Duration",
            value: "${booking.durationMinutes} minutes",
          ),

          const SizedBox(height: 12),

          // PRICE
          _InfoRow(
            icon: Icons.currency_rupee_outlined,
            label: "Price",
            value: "₹${booking.price.toStringAsFixed(2)}",
          ),

          // ADDITIONAL INFO
          // if (booking.requiresExpertApproval) ...[
          //   const SizedBox(height: 12),
          //   _InfoChip(
          //     icon: Icons.approval_outlined,
          //     label: "Requires Expert Approval",
          //     color: Colors.orange,
          //   ),
          // ],

          // if (booking.canBeCancelled) ...[
          //   const SizedBox(height: 12),
          //   _InfoChip(
          //     icon: Icons.cancel_outlined,
          //     label: "Can be cancelled",
          //     color: Colors.blue,
          //   ),
          // ],

          // BOOKING ID
          const SizedBox(height: 16),
          Text(
            "Booking ID: ${booking.uuid.substring(0, 8)}...",
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.4),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    return "${dateFormat.format(dt)} at ${timeFormat.format(dt)}";
  }
}

// ===================================================================
// STATUS BADGE
// ===================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: config.color,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PENDING':
        return _StatusConfig(label: 'PENDING', color: Colors.orange);
      case 'CONFIRMED':
        return _StatusConfig(label: 'CONFIRMED', color: Colors.blue);
      case 'COMPLETED':
        return _StatusConfig(label: 'COMPLETED', color: Colors.green);
      case 'DECLINED':
        return _StatusConfig(label: 'DECLINED', color: Colors.red);
      case 'CANCELLED':
        return _StatusConfig(label: 'CANCELLED', color: Colors.red);
      default:
        return _StatusConfig(label: status, color: Colors.grey);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  _StatusConfig({required this.label, required this.color});
}

// ===================================================================
// INFO ROW
// ===================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// INFO CHIP
// ===================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
