import 'dart:async';
import 'dart:io' show Directory, File;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:dio/dio.dart' as dio_lib;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:q_kics/call/providers/call_notifier.dart';
import 'package:q_kics/call/models/call_models.dart';
import 'package:q_kics/call/services/call_api_service.dart';
import 'package:q_kics/call/utils/web_fullscreen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

// Convenience: true only on physical mobile platforms (not web, not desktop).
bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
//
// Wraps its own ProviderScope override so callNotifierProvider is scoped
// exactly to this screen's lifetime — no autoDispose race conditions.
// ─────────────────────────────────────────────────────────────────────────────
class CallScreen extends StatelessWidget {
  final String roomId;
  final String authToken;
  final int currentUserId;
  final String currentUserName;
  final bool initialCameraEnabled;
  final bool initialMicEnabled;
  final int meetingDurationMinutes;

  const CallScreen({
    super.key,
    required this.roomId,
    required this.authToken,
    required this.currentUserId,
    required this.currentUserName,
    this.initialCameraEnabled = true,
    this.initialMicEnabled = true,
    this.meetingDurationMinutes = 0,
  });

  @override
  Widget build(BuildContext context) {
    // The CallNotifier lives in the root ProviderScope so it is NOT disposed
    // when this screen is popped (e.g., during screen sharing).
    return _CallBody(
      roomId: roomId,
      authToken: authToken,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      initialCameraEnabled: initialCameraEnabled,
      initialMicEnabled: initialMicEnabled,
      meetingDurationMinutes: meetingDurationMinutes,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _CallBody extends ConsumerStatefulWidget {
  final String roomId;
  final String authToken;
  final int currentUserId;
  final String currentUserName;
  final bool initialCameraEnabled;
  final bool initialMicEnabled;
  final int meetingDurationMinutes;

  const _CallBody({
    required this.roomId,
    required this.authToken,
    required this.currentUserId,
    required this.currentUserName,
    required this.initialCameraEnabled,
    required this.initialMicEnabled,
    required this.meetingDurationMinutes,
  });

  @override
  ConsumerState<_CallBody> createState() => _CallBodyState();
}

class _CallBodyState extends ConsumerState<_CallBody>
    with TickerProviderStateMixin {
  bool _controlsVisible = true;
  Timer? _hideTimer;

  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final FocusNode _chatFocus = FocusNode();
  Offset _pipOffset = const Offset(16, 100);

  late final AnimationController _controlsAnim;
  late final AnimationController _chatAnim;

  @override
  void initState() {
    super.initState();
    _controlsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
    _chatAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // orientation lock + system UI hiding are mobile-only APIs.
    if (_isMobilePlatform) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // Keep screen on for the entire duration of the call.
    try { WakelockPlus.enable(); } catch (_) {}

    // Start joining immediately — no postFrameCallback delay so the UI
    // jumps to "loading" state on the very first rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCall());

    _resetHideTimer();
  }

  Future<void> _initCall() async {
    final notifier = ref.read(callNotifierProvider.notifier);
    final phase = ref.read(callNotifierProvider).phase;

    // Returning to a minimized call — just un-minimize, no need to rejoin.
    if (phase == CallPhase.connected || phase == CallPhase.loading) {
      notifier.unMinimizeCall();
      return;
    }

    // permission_handler only works on mobile — web uses browser prompts.
    if (_isMobilePlatform) {
      await [Permission.camera, Permission.microphone].request();
    }
    if (!mounted) return;
    notifier.joinCall(
      roomId: widget.roomId,
      authToken: widget.authToken,
      currentUserId: widget.currentUserId,
      initialCameraEnabled: widget.initialCameraEnabled,
      initialMicEnabled: widget.initialMicEnabled,
      meetingDurationMinutes: widget.meetingDurationMinutes,
    );
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
      _controlsAnim.forward();
    }
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !ref.read(callNotifierProvider).showChat) {
        setState(() => _controlsVisible = false);
        _controlsAnim.reverse();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(callNotifierProvider.notifier).sendChatMessage(text);
    ref.read(callNotifierProvider.notifier).sendTyping(false);
    _chatCtrl.clear();
    _chatFocus.requestFocus();
  }

  /// Toggle the control bar visibility while the chat panel is open.
  void _toggleControlsFromChat() {
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
      _controlsAnim.reverse();
    } else {
      setState(() => _controlsVisible = true);
      _controlsAnim.forward();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controlsAnim.dispose();
    _chatAnim.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _chatFocus.dispose();
    try { WakelockPlus.disable(); } catch (_) {}
    if (_isMobilePlatform) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (kIsWeb) exitCallFullscreen();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ── Side effects (ref.listen never causes a rebuild) ──────────────────────
    ref.listen<CallPhase>(
      callNotifierProvider.select((s) => s.phase),
      (_, phase) {
        if (phase == CallPhase.ended && mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    ref.listen<int>(
      callNotifierProvider.select((s) => s.chatMessages.length),
      (prev, next) { if (next > (prev ?? 0)) _scrollToBottom(); },
    );

    ref.listen<bool>(
      callNotifierProvider.select((s) => s.showChat),
      (_, show) {
        if (show) {
          _chatAnim.forward();
          _hideTimer?.cancel();
          // Hide the control bar so it doesn't cover the chat input field.
          if (_controlsVisible) {
            setState(() => _controlsVisible = false);
            _controlsAnim.reverse();
          }
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _chatFocus.requestFocus();
          });
        } else {
          _chatFocus.unfocus();
          _chatAnim.reverse();
          _resetHideTimer();
        }
      },
    );

    // ── Read only what drives conditional rendering ───────────────────────────
    final phase = ref.watch(callNotifierProvider.select((s) => s.phase));
    final showChat = ref.watch(callNotifierProvider.select((s) => s.showChat));
    final isConnected = phase == CallPhase.connected;
    final isLoading = phase == CallPhase.loading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final callState = ref.read(callNotifierProvider);
        if (callState.isScreenSharing) {
          ref.read(callNotifierProvider.notifier).minimizeCall();
          Navigator.of(context).pop();
          return;
        }
        final room = callState.callRoom;
        if (room != null) {
          await ref.read(callNotifierProvider.notifier).endCall(room.id);
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetHideTimer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Main video area ────────────────────────────────────────────
            // Priority: remote screen-share → remote camera → waiting/error.
            Consumer(
              builder: (_, ref, __) {
                final p = ref.watch(callNotifierProvider.select((s) => s.phase));
                final screenShareTrack = ref.watch(callNotifierProvider.select((s) => s.remoteScreenShareTrack));
                final cameraTrack = ref.watch(callNotifierProvider.select((s) => s.remoteVideoTrack));
                final callRoom = ref.watch(callNotifierProvider.select((s) => s.callRoom));

                if (p == CallPhase.error) {
                  final msg = ref.watch(callNotifierProvider.select((s) => s.errorMessage));
                  return _ErrorView(message: msg ?? 'An error occurred.');
                }

                // Screen share takes over the full main view.
                if (screenShareTrack != null) {
                  return IgnorePointer(child: VideoTrackRenderer(screenShareTrack));
                }

                if (cameraTrack != null) {
                  return IgnorePointer(child: VideoTrackRenderer(cameraTrack));
                }

                final remoteName = _remoteNameFrom(callRoom);
                return _WaitingView(
                  remoteName: remoteName,
                  isConnected: p == CallPhase.connected,
                );
              },
            ),

            // ── 2. Top bar ─────────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: AnimatedBuilder(
                animation: _controlsAnim,
                builder: (_, __) => Opacity(
                  opacity: _controlsAnim.value,
                  child: _TopBarContent(
                    currentUserId: widget.currentUserId,
                    onBack: () async {
                      final nav = Navigator.of(context);
                      final callState = ref.read(callNotifierProvider);
                      if (callState.isScreenSharing) {
                        // Minimize — leave the screen but keep call running.
                        ref.read(callNotifierProvider.notifier).minimizeCall();
                        nav.pop();
                        return;
                      }
                      final room = callState.callRoom;
                      if (room != null) {
                        await ref.read(callNotifierProvider.notifier).endCall(room.id);
                      }
                      if (mounted) nav.pop();
                    },
                    onFullscreen: kIsWeb ? requestCallFullscreen : null,
                  ),
                ),
              ),
            ),

            // ── 3. Local self-view PiP ─────────────────────────────────────────
            if (isConnected)
              Consumer(
                builder: (_, ref, __) {
                  final localTrack = ref.watch(callNotifierProvider.select((s) => s.localVideoTrack));
                  final camOn = ref.watch(callNotifierProvider.select((s) => s.cameraEnabled));
                  final micOn = ref.watch(callNotifierProvider.select((s) => s.micEnabled));

                  return Positioned(
                    left: _pipOffset.dx,
                    top: _pipOffset.dy,
                    child: GestureDetector(
                      onPanUpdate: (d) {
                        final size = MediaQuery.of(context).size;
                        setState(() {
                          _pipOffset = Offset(
                            (_pipOffset.dx + d.delta.dx).clamp(0, size.width - 100),
                            (_pipOffset.dy + d.delta.dy).clamp(0, size.height - 140),
                          );
                        });
                      },
                      child: _PipView(
                        localTrack: localTrack,
                        cameraOn: camOn,
                        micOn: micOn,
                        userName: widget.currentUserName,
                      ),
                    ),
                  );
                },
              ),

            // ── 4. Remote camera PiP (Google Meet style) ──────────────────────
            // Visible only when the remote participant is sharing their screen.
            // Shows their camera feed (or avatar if camera off) in a fixed
            // top-right corner tile, mirroring the Meet experience.
            Consumer(
              builder: (_, ref, __) {
                final isRemoteSharing = ref.watch(callNotifierProvider.select((s) => s.isRemoteScreenSharing));
                if (!isRemoteSharing) return const SizedBox.shrink();
                final cameraTrack = ref.watch(callNotifierProvider.select((s) => s.remoteVideoTrack));
                final callRoom = ref.watch(callNotifierProvider.select((s) => s.callRoom));
                final remoteName = callRoom != null
                    ? (callRoom.user.id == widget.currentUserId
                        ? callRoom.advisor.fullName
                        : callRoom.user.fullName)
                    : 'Participant';
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 72,
                  right: 16,
                  child: _RemoteCameraPip(
                    remoteTrack: cameraTrack,
                    remoteName: remoteName,
                  ),
                );
              },
            ),

            // ── 4b. "X is sharing screen" banner ──────────────────────────────
            Consumer(
              builder: (_, ref, __) {
                final isRemoteSharing = ref.watch(callNotifierProvider.select((s) => s.isRemoteScreenSharing));
                if (!isRemoteSharing) return const SizedBox.shrink();
                final callRoom = ref.watch(callNotifierProvider.select((s) => s.callRoom));
                final remoteName = callRoom != null
                    ? (callRoom.user.id == widget.currentUserId
                        ? callRoom.advisor.fullName
                        : callRoom.user.fullName)
                    : 'Participant';
                return Positioned(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.present_to_all_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$remoteName is sharing their screen',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── 5. Chat + Notes panel ──────────────────────────────────────────
            if (showChat)
              Positioned(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * 0.35,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(CurvedAnimation(parent: _chatAnim, curve: Curves.easeOut)),
                  child: _CallPanel(
                    roomId: widget.roomId,
                    chatCtrl: _chatCtrl,
                    chatScroll: _chatScroll,
                    chatFocus: _chatFocus,
                    onSend: _sendMessage,
                    onClose: () => ref.read(callNotifierProvider.notifier).toggleChat(),
                    onTyping: (v) => ref.read(callNotifierProvider.notifier).sendTyping(v.isNotEmpty),
                    controlsVisible: _controlsVisible,
                    onToggleControls: _toggleControlsFromChat,
                  ),
                ),
              ),

            // ── 5. Typing banner ───────────────────────────────────────────────
            Consumer(
              builder: (_, ref, __) {
                final isTyping = ref.watch(callNotifierProvider.select((s) => s.isRemoteTyping));
                if (!isTyping) return const SizedBox.shrink();
                final name = ref.watch(callNotifierProvider.select((s) => s.remoteTypingUsername));
                return Positioned(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$name is typing', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 8),
                        const _TypingDots(),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── 6. Control bar ─────────────────────────────────────────────────
            if (isConnected || isLoading)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedBuilder(
                  animation: _controlsAnim,
                  builder: (_, __) => Opacity(
                    opacity: _controlsAnim.value,
                    child: Consumer(
                      builder: (_, ref, __) {
                        final micOn = ref.watch(callNotifierProvider.select((s) => s.micEnabled));
                        final camOn = ref.watch(callNotifierProvider.select((s) => s.cameraEnabled));
                        final chatActive = ref.watch(callNotifierProvider.select((s) => s.showChat));
                        final sharing = ref.watch(callNotifierProvider.select((s) => s.isScreenSharing));
                        final connected = ref.watch(callNotifierProvider.select((s) => s.isConnected));
                        final notifier = ref.read(callNotifierProvider.notifier);

                        return _ControlBarContent(
                          micOn: micOn,
                          camOn: camOn,
                          chatActive: chatActive,
                          screenSharing: sharing,
                          enabled: connected,
                          onMic: () { _resetHideTimer(); notifier.toggleMic(); },
                          onCamera: () { _resetHideTimer(); notifier.toggleCamera(); },
                          onFlip: () { _resetHideTimer(); notifier.flipCamera(); },
                          onScreenShare: () { _resetHideTimer(); notifier.toggleScreenShare(); },
                          onChat: () { _resetHideTimer(); notifier.toggleChat(); },
                          onEnd: () async {
                            final confirmed = await _showEndCallDialog();
                            if (confirmed == true) {
                              final room = ref.read(callNotifierProvider).callRoom;
                              if (room != null) await notifier.endCall(room.id);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

            // ── 7. Screen-share active banner ─────────────────────────────────
            Consumer(
              builder: (_, ref, __) {
                final sharing = ref.watch(callNotifierProvider.select((s) => s.isScreenSharing));
                if (!sharing) return const SizedBox.shrink();
                return Positioned(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                  left: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => ref.read(callNotifierProvider.notifier).toggleScreenShare(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.screen_share_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'You are sharing your screen',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Stop',
                            style: TextStyle(color: Color(0xFF90CAF9), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── 9. Time-warning banner (last 60 s) ────────────────────────────
            Consumer(
              builder: (_, ref, __) {
                final warning = ref.watch(callNotifierProvider.select((s) => s.isTimeWarning));
                final remaining = ref.watch(callNotifierProvider.select((s) => s.formattedTimeRemaining));
                if (!warning) return const SizedBox.shrink();
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 20,
                  right: 20,
                  child: _TimeWarningBanner(timeRemaining: remaining),
                );
              },
            ),

            // ── 10. Connecting cover (shown until call is live) ────────────────
            // This ensures the screen is NEVER blank — always shows progress.
            if (!isConnected && phase != CallPhase.error)
              const _ConnectingCover(),
          ],
        ),
      ),
    ), // end Scaffold
    ); // end PopScope
  }

  String _remoteNameFrom(CallRoom? room) {
    if (room == null) return 'Participant';
    return room.user.id == widget.currentUserId
        ? room.advisor.fullName
        : room.user.fullName;
  }

  Future<bool?> _showEndCallDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Call?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to leave this meeting?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connecting cover — sits on top of everything until the call is live.
// This prevents ANY blank/black frame from being visible to the user.
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectingCover extends StatelessWidget {
  const _ConnectingCover();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F0F1A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Color(0xFF6C63FF),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up your call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Warning banner — pulsing red strip shown when ≤ 60 s remain
// ─────────────────────────────────────────────────────────────────────────────
class _TimeWarningBanner extends StatefulWidget {
  final String timeRemaining;
  const _TimeWarningBanner({required this.timeRemaining});

  @override
  State<_TimeWarningBanner> createState() => _TimeWarningBannerState();
}

class _TimeWarningBannerState extends State<_TimeWarningBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Opacity(
        opacity: 0.7 + _pulse.value * 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Meeting ends in ${widget.timeRemaining}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar content (reads from provider via Consumer in parent)
// ─────────────────────────────────────────────────────────────────────────────
class _TopBarContent extends ConsumerWidget {
  final int currentUserId;
  final VoidCallback onBack;
  final VoidCallback? onFullscreen; // web-only; null on mobile

  const _TopBarContent({
    required this.currentUserId,
    required this.onBack,
    this.onFullscreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callRoom = ref.watch(callNotifierProvider.select((s) => s.callRoom));
    final isConnected = ref.watch(callNotifierProvider.select((s) => s.isConnected));
    final hasTimeLimit = ref.watch(callNotifierProvider.select((s) => s.hasTimeLimit));
    final timeLabel = ref.watch(callNotifierProvider.select((s) =>
        s.hasTimeLimit ? s.formattedTimeRemaining : s.formattedDuration));
    final isWarning = ref.watch(callNotifierProvider.select((s) => s.isTimeWarning));
    final participants = ref.watch(callNotifierProvider.select((s) => s.remoteParticipantCount));

    String remoteName = 'Connecting...';
    if (callRoom != null) {
      remoteName = callRoom.user.id == currentUserId
          ? callRoom.advisor.fullName
          : callRoom.user.fullName;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remoteName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isConnected)
                  Text(
                    'In meeting',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                  ),
              ],
            ),
          ),
          // Fullscreen button — web only, always visible so the user can
          // enter OS-level fullscreen at any point during the call.
          if (onFullscreen != null) ...[
            GestureDetector(
              onTap: onFullscreen,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 8),
          ],

          if (isConnected) ...[
            // Time badge — green elapsed OR red/orange countdown
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWarning
                    ? Colors.red.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isWarning)
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 14)
                  else
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (hasTimeLimit && !isWarning) ...[
                    const SizedBox(width: 4),
                    Text(
                      'left',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 22),
                ),
                if (participants > 0)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(10)),
                      child: Text('${participants + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PiP self-view
// ─────────────────────────────────────────────────────────────────────────────
class _PipView extends StatelessWidget {
  final LocalVideoTrack? localTrack;
  final bool cameraOn;
  final bool micOn;
  final String userName;

  const _PipView({required this.localTrack, required this.cameraOn, required this.micOn, required this.userName});

  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100, height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Stack(
          children: [
            if (localTrack != null && cameraOn)
              Positioned.fill(
                child: IgnorePointer(child: VideoTrackRenderer(localTrack!)),
              )
            else
              Center(
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                ),
              ),
            Positioned(
              bottom: 6, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                  child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
            if (!micOn)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), shape: BoxShape.circle),
                  child: const Icon(Icons.mic_off_rounded, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Remote camera PiP (shown in corner when remote is screen-sharing)
// ─────────────────────────────────────────────────────────────────────────────
class _RemoteCameraPip extends StatelessWidget {
  final VideoTrack? remoteTrack;
  final String remoteName;
  const _RemoteCameraPip({required this.remoteTrack, required this.remoteName});

  String get _initials {
    final parts = remoteName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90, height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Stack(
          children: [
            if (remoteTrack != null)
              Positioned.fill(child: IgnorePointer(child: VideoTrackRenderer(remoteTrack!)))
            else
              Center(
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                ),
              ),
            Positioned(
              bottom: 5, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: Text(remoteName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control bar
// ─────────────────────────────────────────────────────────────────────────────
class _ControlBarContent extends StatelessWidget {
  final bool micOn;
  final bool camOn;
  final bool chatActive;
  final bool screenSharing;
  final bool enabled;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onChat;
  final VoidCallback onScreenShare;
  final VoidCallback onEnd;

  const _ControlBarContent({
    required this.micOn,
    required this.camOn,
    required this.chatActive,
    required this.screenSharing,
    required this.enabled,
    required this.onMic,
    required this.onCamera,
    required this.onFlip,
    required this.onChat,
    required this.onScreenShare,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 32, left: 12, right: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Btn(icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded, label: micOn ? 'Mute' : 'Unmute', active: micOn, onTap: enabled ? onMic : null),
          _Btn(icon: camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, label: camOn ? 'Camera' : 'Cam Off', active: camOn, onTap: enabled ? onCamera : null),
          _Btn(icon: Icons.flip_camera_ios_rounded, label: 'Flip', onTap: enabled ? onFlip : null),
          _Btn(
            icon: screenSharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
            label: screenSharing ? 'Stop' : 'Share',
            highlighted: screenSharing,
            onTap: enabled ? onScreenShare : null,
          ),
          _Btn(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', highlighted: chatActive, onTap: enabled ? onChat : null),
          _Btn(icon: Icons.call_end_rounded, label: 'End', isDestructive: true, onTap: onEnd),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Combined Chat + Notes panel (tabbed)
// ─────────────────────────────────────────────────────────────────────────────
class _CallPanel extends ConsumerStatefulWidget {
  final String roomId;
  final TextEditingController chatCtrl;
  final ScrollController chatScroll;
  final FocusNode chatFocus;
  final VoidCallback onSend;
  final VoidCallback onClose;
  final ValueChanged<String> onTyping;
  final bool controlsVisible;
  final VoidCallback onToggleControls;

  const _CallPanel({
    required this.roomId,
    required this.chatCtrl,
    required this.chatScroll,
    required this.chatFocus,
    required this.onSend,
    required this.onClose,
    required this.onTyping,
    required this.controlsVisible,
    required this.onToggleControls,
  });

  @override
  ConsumerState<_CallPanel> createState() => _CallPanelState();
}

class _CallPanelState extends ConsumerState<_CallPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _callApi = CallApiService();

  List<Map<String, dynamic>> _notes = [];
  bool _notesLoading = false;
  bool _notesSaving = false;
  String? _notesError;
  bool _isUploading = false;

  final _noteCtrl = TextEditingController();
  final _noteScroll = ScrollController();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.index == 1 && _notes.isEmpty && !_notesLoading) {
        _fetchNotes();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _noteCtrl.dispose();
    _noteScroll.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() { _notesLoading = true; _notesError = null; });
    try {
      final notes = await _callApi.getNotes(widget.roomId);
      if (mounted) setState(() => _notes = notes);
    } catch (e) {
      if (mounted) setState(() => _notesError = 'Failed to load notes');
    } finally {
      if (mounted) setState(() => _notesLoading = false);
    }
  }

  Future<void> _saveNote() async {
    final content = _noteCtrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _notesSaving = true);
    try {
      final created = await _callApi.createNote(widget.roomId, content);
      if (mounted) {
        setState(() => _notes.insert(0, created));
        _noteCtrl.clear();
        _noteFocus.unfocus();
        _scrollNotesToTop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save note'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _notesSaving = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    // On web, load bytes into memory; on mobile, read from the file path.
    final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    List<int>? bytes;
    if (kIsWeb) {
      bytes = file.bytes?.toList();
    } else {
      final path = file.path;
      if (path != null) bytes = await File(path).readAsBytes();
    }
    if (bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final data = await _callApi.uploadFile(widget.roomId, file.name, bytes);
      debugPrint('[CallChat] uploadFile response: $data');
      if (mounted) ref.read(callNotifierProvider.notifier).addFileMessage(data);
    } catch (e) {
      debugPrint('[CallChat] uploadFile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollNotesToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_noteScroll.hasClients) {
        _noteScroll.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context, ) {
    final messages = ref.watch(callNotifierProvider.select((s) => s.chatMessages));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF01A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    indicatorColor: const Color(0xFF6C63FF),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: 'Chat'),
                      Tab(text: 'Notes'),
                    ],
                  ),
                ),
                Tooltip(
                  message: widget.controlsVisible ? 'Hide controls' : 'Show controls',
                  child: IconButton(
                    onPressed: widget.onToggleControls,
                    icon: Icon(
                      widget.controlsVisible
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      color: widget.controlsVisible
                          ? const Color(0xFF6C63FF)
                          : Colors.white38,
                      size: 22,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70, size: 28),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // ── Tab content ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ─── Chat Tab ─────────────────────────────────────────────────
                Column(
                  children: [
                    Expanded(
                      child: messages.isEmpty
                          ? Center(
                              child: Text(
                                'No messages yet.\nSay hello!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              controller: widget.chatScroll,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              itemCount: messages.length,
                              itemBuilder: (_, i) =>
                                  _ChatBubble(msg: messages[i]),
                            ),
                    ),
                    _ChatInput(
                      chatCtrl: widget.chatCtrl,
                      chatFocus: widget.chatFocus,
                      onSend: widget.onSend,
                      onTyping: widget.onTyping,
                      onAttach: _pickAndUploadFile,
                      isUploading: _isUploading,
                    ),
                  ],
                ),

                // ─── Notes Tab ────────────────────────────────────────────────
                Column(
                  children: [
                    Expanded(child: _buildNotesBody()),
                    _NotesInput(
                      noteCtrl: _noteCtrl,
                      noteFocus: _noteFocus,
                      isSaving: _notesSaving,
                      onSave: _saveNote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesBody() {
    if (_notesLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              color: Color(0xFF6C63FF), strokeWidth: 2.5),
        ),
      );
    }

    if (_notesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 36),
            const SizedBox(height: 8),
            Text(_notesError!,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _fetchNotes,
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF6C63FF))),
            ),
          ],
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.note_alt_outlined,
                  color: Color(0xFF6C63FF), size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notes yet',
              style: TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Write your key takeaways\nbelow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _noteScroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _notes.length,
      itemBuilder: (_, i) => _NoteCard(note: _notes[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat text input bar (extracted from panel)
// ─────────────────────────────────────────────────────────────────────────────
class _ChatInput extends StatelessWidget {
  final TextEditingController chatCtrl;
  final FocusNode chatFocus;
  final VoidCallback onSend;
  final ValueChanged<String> onTyping;
  final VoidCallback onAttach;
  final bool isUploading;

  const _ChatInput({
    required this.chatCtrl,
    required this.chatFocus,
    required this.onSend,
    required this.onTyping,
    required this.onAttach,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Attach file button
          GestureDetector(
            onTap: isUploading ? null : onAttach,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF), strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.attach_file_rounded,
                      color: Colors.white70, size: 20),
            ),
          ),
          Expanded(
            child: TextField(
              controller: chatCtrl,
              focusNode: chatFocus,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Message everyone...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none),
              ),
              onChanged: onTyping,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes text input bar
// ─────────────────────────────────────────────────────────────────────────────
class _NotesInput extends StatelessWidget {
  final TextEditingController noteCtrl;
  final FocusNode noteFocus;
  final bool isSaving;
  final VoidCallback onSave;

  const _NotesInput({
    required this.noteCtrl,
    required this.noteFocus,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: noteCtrl,
              focusNode: noteFocus,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Write a note...',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onSave(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSaving ? null : onSave,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSaving
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                color: isSaving
                    ? Colors.white.withValues(alpha: 0.12)
                    : null,
                shape: BoxShape.circle,
              ),
              child: isSaving
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF), strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single note card
// ─────────────────────────────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final content = note['content'] as String? ?? '';
    final rawTs = note['created_at'] ?? note['timestamp'];
    DateTime? ts;
    try {
      if (rawTs != null) ts = DateTime.parse(rawTs.toString()).toLocal();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sticky_note_2_outlined,
                  color: Color(0xFF6C63FF), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
          if (ts != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('MMM dd, HH:mm').format(ts),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waiting background (no remote video yet)
// ─────────────────────────────────────────────────────────────────────────────
class _WaitingView extends StatelessWidget {
  final String remoteName;
  final bool isConnected;

  const _WaitingView({required this.remoteName, required this.isConnected});

  String get _initials {
    final parts = remoteName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112, height: 112,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 20),
          Text(remoteName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            isConnected ? 'Camera is off' : 'Waiting to connect...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control button
// ─────────────────────────────────────────────────────────────────────────────
class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final bool highlighted;
  final bool isDestructive;

  const _Btn({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = true,
    this.highlighted = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color iconCol;
    if (isDestructive) {
      bg = const Color(0xFFE53935); iconCol = Colors.white;
    } else if (highlighted) {
      bg = const Color(0xFF6C63FF); iconCol = Colors.white;
    } else if (!active) {
      bg = Colors.white.withValues(alpha: 0.15); iconCol = Colors.white.withValues(alpha: 0.7);
    } else {
      bg = Colors.white.withValues(alpha: 0.18); iconCol = Colors.white;
    }
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconCol, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final CallChatMessage msg;
  const _ChatBubble({required this.msg});

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[CallChat] launchUrl error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFile = msg.isFile && (msg.fileUrl?.isNotEmpty ?? false);
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
      bottomRight: Radius.circular(msg.isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!msg.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                msg.senderUsername,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),

          // ── Bubble ────────────────────────────────────────────────────────
          GestureDetector(
            onTap: isFile ? () => _openUrl(msg.fileUrl!) : null,
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: EdgeInsets.symmetric(
                horizontal: isFile ? 12 : 14,
                vertical: isFile ? 10 : 10,
              ),
              decoration: BoxDecoration(
                gradient: msg.isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)
                    : null,
                color: msg.isMe ? null : Colors.white.withValues(alpha: 0.12),
                borderRadius: bubbleRadius,
              ),
              child: isFile ? _FileBubbleBody(msg: msg) : _TextBubbleBody(text: msg.text),
            ),
          ),

          // ── Timestamp ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              DateFormat('HH:mm').format(msg.timestamp.toLocal()),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// Plain text body
class _TextBubbleBody extends StatelessWidget {
  final String text;
  const _TextBubbleBody({required this.text});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 14));
}

// File attachment body — icon + name + open/download actions
class _FileBubbleBody extends StatefulWidget {
  final CallChatMessage msg;
  const _FileBubbleBody({required this.msg});

  @override
  State<_FileBubbleBody> createState() => _FileBubbleBodyState();
}

class _FileBubbleBodyState extends State<_FileBubbleBody> {
  bool _downloading = false;
  double? _progress; // 0.0 – 1.0

  static IconData _iconFor(String? fileName) {
    final ext = (fileName ?? '').split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) return Icons.image_rounded;
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return Icons.videocam_rounded;
    if (['mp3', 'wav', 'aac', 'm4a'].contains(ext)) return Icons.audiotrack_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_rounded;
    if (['ppt', 'pptx'].contains(ext)) return Icons.slideshow_rounded;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _download() async {
    final url = widget.msg.fileUrl;
    final fileName = widget.msg.fileName?.isNotEmpty == true
        ? widget.msg.fileName!
        : 'download';
    if (url == null || _downloading) return;

    // Web: just open in browser — no local download.
    if (kIsWeb) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {}
      return;
    }

    setState(() { _downloading = true; _progress = 0; });
    try {
      // On Android < 10, request storage permission.
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.storage.request();
      }

      // Determine save path.
      String savePath;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          savePath = '${downloadsDir.path}/$fileName';
        } else {
          final dir = await getExternalStorageDirectory() ??
              await getTemporaryDirectory();
          savePath = '${dir.path}/$fileName';
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$fileName';
      }

      // Download.
      await dio_lib.Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Saved: $fileName'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await launchUrl(
                  Uri.file(savePath),
                  mode: LaunchMode.externalApplication,
                );
              } catch (_) {}
            },
          ),
        ));
      }
    } catch (e) {
      debugPrint('[CallChat] download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() { _downloading = false; _progress = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.msg.fileName?.isNotEmpty == true
        ? widget.msg.fileName!
        : widget.msg.text.isNotEmpty
            ? widget.msg.text
            : 'Attachment';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(widget.msg.fileName), color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Download button
            GestureDetector(
              onTap: _downloading ? null : _download,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: _downloading
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          value: _progress,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        // Progress bar during download
        if (_downloading && _progress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 2,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing dots animation
// ─────────────────────────────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.2;
          final t = ((_c.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = (t < 0.5 ? 1 + t * 0.6 : 1.3 - (t - 0.5) * 0.6).clamp(1.0, 1.3);
          return Transform.scale(
            scale: scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5, height: 5,
              decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
            ),
          );
        }),
      ),
    );
  }
}
