import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../booking/models/booking.dart';
import '../booking/models/investor_booking.dart';
import '../call/screens/call_lobby_screen.dart';
import '../call/screens/call_screen.dart';
import '../call/services/call_api_service.dart';
import '../call/providers/call_notifier.dart';
import '../providers/api_provider.dart';
import '../providers/booking_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sessions page — Expert + Investor tabs
// ─────────────────────────────────────────────────────────────────────────────
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
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
          'My Sessions',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: _fetch,
            tooltip: 'Refresh',
          ),
        ],
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Expert Sessions ─────────────────────────────────────
          _ExpertSessionsTab(onRefresh: _fetch),
          // ── Tab 2: Investor Sessions ───────────────────────────────────
          _InvestorSessionsTab(onRefresh: _fetch),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Expert Sessions
// ─────────────────────────────────────────────────────────────────────────────
class _ExpertSessionsTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _ExpertSessionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (provider.isLoadingBookings &&
        provider.userBookings.isEmpty &&
        provider.expertBookings.isEmpty) {
      return _buildLoading();
    }

    final currentUserId = context.read<ApiProvider>().currentUser?.id;
    final sessions = _filteredSessions(provider, currentUserId);

    if (sessions.isEmpty) {
      return _buildEmptyState(
        theme,
        cs,
        icon: Icons.videocam_off_rounded,
        iconColor: const Color(0xFF6C63FF),
        title: 'No upcoming expert sessions',
        subtitle: 'Your confirmed expert sessions will appear here.',
      );
    }

    final now = DateTime.now();
    final live = sessions
        .where((b) =>
            !now.isBefore(b.startDatetime.toLocal()) &&
            !now.isAfter(b.endDatetime.toLocal()))
        .toList();
    final upcoming = sessions
        .where((b) => now.isBefore(b.startDatetime.toLocal()))
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          if (live.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.fiber_manual_record,
              iconColor: Colors.red,
              label: 'Live Now',
              count: live.length,
            ),
            const SizedBox(height: 12),
            ...live.map((b) => _SessionCard(
                  booking: b,
                  currentUserId: currentUserId,
                  isLive: true,
                )),
            const SizedBox(height: 24),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.upcoming_rounded,
              iconColor: const Color(0xFF6C63FF),
              label: 'Upcoming',
              count: upcoming.length,
            ),
            const SizedBox(height: 12),
            ...upcoming.map((b) => _SessionCard(
                  booking: b,
                  currentUserId: currentUserId,
                  isLive: false,
                )),
          ],
        ],
      ),
    );
  }

  List<Booking> _filteredSessions(BookingProvider provider, int? currentUserId) {
    if (currentUserId == null) return [];
    final byUuid = <String, Booking>{};
    for (final b in [...provider.userBookings, ...provider.expertBookings]) {
      byUuid[b.uuid] = b;
    }
    final now = DateTime.now();
    return byUuid.values
        .where((b) =>
            b.isConfirmed &&
            (b.user == currentUserId || b.expert == currentUserId) &&
            b.endDatetime.toLocal().isAfter(now))
        .toList()
      ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Investor Sessions
// ─────────────────────────────────────────────────────────────────────────────
class _InvestorSessionsTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _InvestorSessionsTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (provider.isLoadingBookings && provider.userInvestorBookings.isEmpty) {
      return _buildLoading();
    }

    final now = DateTime.now();
    final confirmed = provider.userInvestorBookings
        .where((b) =>
            b.status == 'CONFIRMED' &&
            b.endDateTime.toLocal().isAfter(now))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    if (confirmed.isEmpty) {
      return _buildEmptyState(
        theme,
        cs,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: Colors.purple,
        title: 'No upcoming investor sessions',
        subtitle: 'Your confirmed investor sessions will appear here.',
      );
    }

    final live = confirmed
        .where((b) =>
            !now.isBefore(b.startDateTime.toLocal()) &&
            !now.isAfter(b.endDateTime.toLocal()))
        .toList();
    final upcoming = confirmed
        .where((b) => now.isBefore(b.startDateTime.toLocal()))
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          if (live.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.fiber_manual_record,
              iconColor: Colors.red,
              label: 'Live Now',
              count: live.length,
            ),
            const SizedBox(height: 12),
            ...live.map((b) => _InvestorSessionCard(booking: b, isLive: true)),
            const SizedBox(height: 24),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.upcoming_rounded,
              iconColor: Colors.purple,
              label: 'Upcoming',
              count: upcoming.length,
            ),
            const SizedBox(height: 12),
            ...upcoming.map((b) => _InvestorSessionCard(booking: b, isLive: false)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Investor Session Card
// ─────────────────────────────────────────────────────────────────────────────
class _InvestorSessionCard extends StatelessWidget {
  final InvestorBooking booking;
  final bool isLive;

  const _InvestorSessionCard({required this.booking, required this.isLive});

  String get _otherName => booking.investorName.isNotEmpty
      ? booking.investorName
      : 'Investor';

  String get _initials {
    final parts = _otherName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _timeLabel() {
    if (isLive) {
      final remaining = booking.endDateTime.toLocal().difference(DateTime.now());
      if (remaining.inHours >= 1) {
        return 'Ends in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
      }
      return 'Ends in ${remaining.inMinutes}m';
    }
    final diff = booking.startDateTime.toLocal().difference(DateTime.now());
    if (diff.inDays >= 1) return 'in ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return 'in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? Colors.red.withValues(alpha: 0.4)
              : Colors.purple.withValues(alpha: 0.25),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.purple.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 12, color: Colors.purple[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Investor Session',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.purple[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _TimeBadge(label: _timeLabel(), isLive: isLive, accentColor: Colors.purple),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 14),

            // ── Date / duration row ───────────────────────────────────────
            Row(
              children: [
                _MiniInfo(
                  icon: Icons.calendar_today_outlined,
                  value: DateFormat('MMM dd, hh:mm a')
                      .format(booking.startDateTime.toLocal()),
                ),
                const SizedBox(width: 16),
                _MiniInfo(
                  icon: Icons.access_time_outlined,
                  value: '${booking.durationMinutes} min',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Status row ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    itemCount: 3,
    itemBuilder: (_, __) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),
  );
}

Widget _buildEmptyState(
  ThemeData theme,
  ColorScheme cs, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert Session card — full inline call action
// ─────────────────────────────────────────────────────────────────────────────
class _SessionCard extends ConsumerStatefulWidget {
  final Booking booking;
  final int? currentUserId;
  final bool isLive;

  const _SessionCard({
    required this.booking,
    required this.currentUserId,
    required this.isLive,
  });

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  final _callApi = CallApiService();
  bool _isCreating = false;

  String get _otherName {
    final uid = widget.currentUserId;
    if (uid == null) return 'Participant';
    return uid == widget.booking.user
        ? widget.booking.expertName
        : widget.booking.userName;
  }

  String get _initials {
    final parts = _otherName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _timeLabel(bool isLive) {
    if (isLive) {
      final end = widget.booking.endDatetime.toLocal();
      final remaining = end.difference(DateTime.now());
      if (remaining.inHours >= 1) {
        return 'Ends in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m';
      }
      return 'Ends in ${remaining.inMinutes}m';
    }
    final start = widget.booking.startDatetime.toLocal();
    final diff = start.difference(DateTime.now());
    if (diff.inDays >= 1) return 'in ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return 'in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final callRoomId = widget.booking.callRoomId;
    final isLive = widget.isLive;

    final callPhase = ref.watch(callNotifierProvider.select((s) => s.phase));
    final activeRoomId =
        ref.watch(callNotifierProvider.select((s) => s.callRoom?.id));
    final isInThisCall = callPhase == CallPhase.connected &&
        activeRoomId != null &&
        activeRoomId == callRoomId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? Colors.red.withValues(alpha: 0.4)
              : cs.onSurface.withValues(alpha: 0.1),
          width: isLive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? Colors.red.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Expert Consultation',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                _TimeBadge(
                  label: _timeLabel(isLive),
                  isLive: isLive,
                  accentColor: const Color(0xFF6C63FF),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniInfo(
                  icon: Icons.calendar_today_outlined,
                  value: DateFormat('MMM dd, hh:mm a')
                      .format(widget.booking.startDatetime.toLocal()),
                ),
                const SizedBox(width: 16),
                _MiniInfo(
                  icon: Icons.access_time_outlined,
                  value: '${widget.booking.durationMinutes} min',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButton(context, isInThisCall, callRoomId),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isInThisCall,
    String? callRoomId,
  ) {
    final api = context.read<ApiProvider>();

    if (isInThisCall) {
      return _CallButton(
        icon: Icons.videocam_rounded,
        label: 'Return to Call',
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        onPressed: () {
          final params = ref.read(callNotifierProvider.notifier).callScreenParams;
          if (params == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CallScreen(
                roomId: params.roomId,
                authToken: params.authToken,
                currentUserId: params.currentUserId,
                currentUserName: params.currentUserName,
                meetingDurationMinutes: params.meetingDurationMinutes,
              ),
            ),
          );
        },
      );
    }

    if (callRoomId == null || callRoomId.isEmpty) {
      return _CallButton(
        icon: _isCreating ? null : Icons.video_call_rounded,
        label: _isCreating ? 'Creating...' : 'Create Meeting',
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        isLoading: _isCreating,
        onPressed: _isCreating ? null : _createMeeting,
      );
    }

    return _CallButton(
      icon: Icons.videocam_rounded,
      label: 'Join Now',
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      onPressed: () {
        final token = api.accessToken;
        final user = api.currentUser;
        if (token == null || user == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallLobbyScreen(
              roomId: callRoomId,
              authToken: token,
              currentUserId: user.id,
              currentUserName: user.fullName,
              meetingTitle: 'Meeting with $_otherName',
              meetingDurationMinutes: widget.booking.durationMinutes,
            ),
          ),
        ).then((_) {
          if (context.mounted) {
            context.read<BookingProvider>().fetchUserBookings();
            context.read<BookingProvider>().fetchExpertBookings();
          }
        });
      },
    );
  }

  Future<void> _createMeeting() async {
    setState(() => _isCreating = true);
    final bookingProvider = context.read<BookingProvider>();
    try {
      await _callApi.createRoomForBooking(widget.booking.uuid);
      if (!mounted) return;
      await bookingProvider.fetchUserBookings();
      await bookingProvider.fetchExpertBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting created successfully.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create meeting: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini info chip
// ─────────────────────────────────────────────────────────────────────────────
class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MiniInfo({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 5),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live / countdown badge — supports custom accent color
// ─────────────────────────────────────────────────────────────────────────────
class _TimeBadge extends StatelessWidget {
  final String label;
  final bool isLive;
  final Color accentColor;

  const _TimeBadge({
    required this.label,
    required this.isLive,
    this.accentColor = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    final color = isLive ? Colors.red : accentColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            isLive ? 'LIVE' : label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient call button
// ─────────────────────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: onPressed != null ? gradient : null,
            color: onPressed == null
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
