import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:q_kics/call/providers/lobby_notifier.dart';
import 'package:q_kics/call/screens/call_screen.dart';
import 'package:q_kics/call/utils/web_fullscreen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pre-join lobby — Google Meet style.
// Uses ConsumerStatefulWidget + Riverpod so each toggle (mic / camera)
// only rebuilds the widget that actually shows the changed value.
// ─────────────────────────────────────────────────────────────────────────────
class CallLobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String authToken;
  final int currentUserId;
  final String currentUserName;
  final String meetingTitle;
  final int meetingDurationMinutes;

  const CallLobbyScreen({
    super.key,
    required this.roomId,
    required this.authToken,
    required this.currentUserId,
    required this.currentUserName,
    required this.meetingTitle,
    this.meetingDurationMinutes = 0,
  });

  @override
  ConsumerState<CallLobbyScreen> createState() => _CallLobbyScreenState();
}

class _CallLobbyScreenState extends ConsumerState<CallLobbyScreen> {
  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_isMobilePlatform) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    // Start camera preview after first frame so the notifier is ready.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(lobbyNotifierProvider.notifier).initPreview(),
    );
  }

  @override
  void dispose() {
    if (_isMobilePlatform) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  Future<void> _joinCall() async {
    // Request OS-level fullscreen SYNCHRONOUSLY here — this is inside a tap
    // handler (user gesture), so browsers will honour the requestFullscreen()
    // call. Any await after this line would break the gesture context.
    if (kIsWeb) requestCallFullscreen();

    final notifier = ref.read(lobbyNotifierProvider.notifier);
    // Snapshot the choices before the async stop
    final camOn = ref.read(lobbyNotifierProvider).cameraOn;
    final micOn = ref.read(lobbyNotifierProvider).micOn;

    await notifier.prepareJoin(); // stops preview track, releases camera HW

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomId: widget.roomId,
          authToken: widget.authToken,
          currentUserId: widget.currentUserId,
          currentUserName: widget.currentUserName,
          initialCameraEnabled: camOn,
          initialMicEnabled: micOn,
          meetingDurationMinutes: widget.meetingDurationMinutes,
        ),
      ),
    );
  }

  String get _initials {
    final parts = widget.currentUserName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build — each section watches only the slice it needs
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safePad = MediaQuery.of(context).padding;
    final isJoining = ref.watch(lobbyNotifierProvider.select((s) => s.joining));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        children: [
          SizedBox(height: safePad.top + 20),

          // ── Header (static — no watch needed) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Text(
                  'Ready to join?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.meetingTitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Camera preview card ───────────────────────────────────────────────
          // Isolated in its own ConsumerWidget so toggles don't rebuild
          // the header or buttons.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _PreviewCard(
                  initials: _initials,
                  currentUserName: widget.currentUserName,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Toggle controls ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mic button rebuilds only when micOn changes
              Consumer(
                builder: (_, ref, __) {
                  final micOn = ref.watch(lobbyNotifierProvider.select((s) => s.micOn));
                  return _LobbyToggle(
                    icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                    label: micOn ? 'Mic on' : 'Mic off',
                    isOn: micOn,
                    onTap: () => ref.read(lobbyNotifierProvider.notifier).toggleMic(),
                  );
                },
              ),
              const SizedBox(width: 40),
              // Camera button rebuilds only when cameraOn changes
              Consumer(
                builder: (_, ref, __) {
                  final camOn = ref.watch(lobbyNotifierProvider.select((s) => s.cameraOn));
                  return _LobbyToggle(
                    icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    label: camOn ? 'Camera on' : 'Camera off',
                    isOn: camOn,
                    onTap: () => ref.read(lobbyNotifierProvider.notifier).toggleCamera(),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Join button ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: isJoining ? null : _joinCall,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                decoration: BoxDecoration(
                  gradient: isJoining
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: isJoining ? const Color(0xFF6C63FF).withValues(alpha: 0.5) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isJoining
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: isJoining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Join Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
            ),
          ),

          SizedBox(height: safePad.bottom + 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview card — watches previewTrack, cameraOn, micOn independently.
// Rebuilds ONLY when the video track or the camera/mic state changes.
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewCard extends ConsumerWidget {
  final String initials;
  final String currentUserName;

  const _PreviewCard({required this.initials, required this.currentUserName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewTrack = ref.watch(lobbyNotifierProvider.select((s) => s.previewTrack));
    final cameraOn = ref.watch(lobbyNotifierProvider.select((s) => s.cameraOn));
    final micOn = ref.watch(lobbyNotifierProvider.select((s) => s.micOn));
    final isLoading = ref.watch(lobbyNotifierProvider.select((s) => s.isLoading));

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video or placeholder
          if (previewTrack != null && cameraOn)
            VideoTrackRenderer(previewTrack)
          else
            _CameraOffPlaceholder(initials: initials, name: currentUserName),

          // Name badge
          Positioned(
            left: 14,
            bottom: 14,
            child: _NameBadge(name: currentUserName),
          ),

          // Mic off indicator
          if (!micOn)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.88),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: 18),
              ),
            ),

          // Loading overlay
          if (isLoading)
            Container(
              color: const Color(0xFF1A1A2E),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CameraOffPlaceholder extends StatelessWidget {
  final String initials;
  final String name;

  const _CameraOffPlaceholder({required this.initials, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Camera is off',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _NameBadge extends StatelessWidget {
  final String name;
  const _NameBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _LobbyToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  const _LobbyToggle({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: isOn ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFE53935),
              shape: BoxShape.circle,
              boxShadow: isOn
                  ? null
                  : [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
