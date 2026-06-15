import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/booking_provider.dart';
import '../booking/models/booking.dart';
import '../booking/models/investor_booking.dart';

class UserBookingsPage extends StatefulWidget {
  const UserBookingsPage({super.key});

  @override
  State<UserBookingsPage> createState() => _UserBookingsPageState();
}

class _UserBookingsPageState extends State<UserBookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    final provider = context.read<BookingProvider>();
    await Future.wait([
      provider.fetchUserBookings(),
      provider.fetchExpertBookings(),
      provider.fetchUserInvestorBookings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
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
          'My Bookings',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Expert'),
            Tab(text: 'Investor'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Expert Bookings ──────────────────────────────────
              _ExpertBookingsTab(provider: provider, onRetry: _fetchAll),
              // ── Tab 2: Investor Bookings ────────────────────────────────
              _InvestorBookingsTab(provider: provider, onRetry: _fetchAll),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Expert Bookings
// ─────────────────────────────────────────────────────────────────────────────
class _ExpertBookingsTab extends StatelessWidget {
  final BookingProvider provider;
  final VoidCallback onRetry;

  const _ExpertBookingsTab({required this.provider, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (provider.isLoadingBookings &&
        provider.userBookings.isEmpty &&
        provider.expertBookings.isEmpty) {
      return _buildLoading();
    }

    if (provider.bookingsError != null &&
        provider.userBookings.isEmpty &&
        provider.expertBookings.isEmpty) {
      return _buildError(provider, context);
    }

    final bookings = _mergedBookings(provider);
    if (bookings.isEmpty) {
      return _emptyState(
        theme,
        cs,
        icon: Icons.calendar_today_outlined,
        title: 'No expert bookings yet',
        subtitle: 'Book an expert to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchUserBookings();
        await provider.fetchExpertBookings();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }

  List<Booking> _mergedBookings(BookingProvider p) {
    final byUuid = <String, Booking>{};
    for (final b in [...p.userBookings, ...p.expertBookings]) {
      byUuid[b.uuid] = b;
    }
    return byUuid.values.toList()
      ..sort((a, b) => b.startDatetime.compareTo(a.startDatetime));
  }

  Widget _buildError(BookingProvider provider, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(provider.bookingsError ?? 'Failed to load bookings'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Investor Bookings
// ─────────────────────────────────────────────────────────────────────────────
class _InvestorBookingsTab extends StatelessWidget {
  final BookingProvider provider;
  final VoidCallback onRetry;

  const _InvestorBookingsTab({required this.provider, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (provider.isLoadingBookings && provider.userInvestorBookings.isEmpty) {
      return _buildLoading();
    }

    final bookings = provider.userInvestorBookings
      ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));

    if (bookings.isEmpty) {
      return _emptyState(
        theme,
        cs,
        icon: Icons.account_balance_wallet_outlined,
        title: 'No investor bookings yet',
        subtitle: 'Book an investor session to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchUserInvestorBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _InvestorBookingCard(booking: bookings[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

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

Widget _emptyState(
  ThemeData theme,
  ColorScheme cs, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: cs.onSurface.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert Booking Card
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        booking.expertName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expert',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
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
            _InfoRow(
              icon: booking.isChat
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.videocam_outlined,
              label: 'Session Type',
              value: booking.isChat ? 'Chat' : 'Video Call',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date & Time',
              value: _fmt(booking.startDatetime),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Duration',
              value: '${booking.durationMinutes} minutes',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.currency_rupee_outlined,
              label: 'Price',
              value: '₹${booking.price.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${DateFormat('MMM dd, yyyy').format(local)} at ${DateFormat('hh:mm a').format(local)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Investor Booking Card
// ─────────────────────────────────────────────────────────────────────────────
class _InvestorBookingCard extends StatelessWidget {
  final InvestorBooking booking;

  const _InvestorBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(booking.investorName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.investorName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 12,
                            color: Colors.purple[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Investor Session',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.purple[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date & Time',
              value: _fmt(booking.startDateTime),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Duration',
              value: '${booking.durationMinutes} minutes',
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    return '${DateFormat('MMM dd, yyyy').format(local)} at ${DateFormat('hh:mm a').format(local)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
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

  ({String label, Color color}) _config(String status) => switch (status) {
        'PENDING'   => (label: 'PENDING',   color: Colors.orange),
        'CONFIRMED' => (label: 'CONFIRMED', color: Colors.blue),
        'COMPLETED' => (label: 'COMPLETED', color: Colors.green),
        'DECLINED'  => (label: 'DECLINED',  color: Colors.red),
        'CANCELLED' => (label: 'CANCELLED', color: Colors.red),
        _           => (label: status,      color: Colors.grey),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
