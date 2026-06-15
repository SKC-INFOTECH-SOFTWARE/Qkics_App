import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' show Helper;
import 'package:livekit_client/livekit_client.dart';
import 'package:q_kics/call/models/call_models.dart';
import 'package:q_kics/call/services/call_api_service.dart';
import 'package:q_kics/call/services/call_chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phase
// ─────────────────────────────────────────────────────────────────────────────
enum CallPhase { idle, loading, connected, ended, error }

// ─────────────────────────────────────────────────────────────────────────────
// Immutable state
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class CallUiState {
  final CallPhase phase;
  final CallRoom? callRoom;
  final String? errorMessage;

  // Local tracks
  final LocalVideoTrack? localVideoTrack;

  // Remote camera track
  final VideoTrack? remoteVideoTrack;

  // Remote screen-share track (separate from camera)
  final VideoTrack? remoteScreenShareTrack;

  final bool cameraEnabled;
  final bool micEnabled;
  final bool frontCamera;
  final List<CallChatMessage> chatMessages;
  final bool showChat;
  final bool isRemoteTyping;
  final String remoteTypingUsername;
  final Duration callDuration;
  final int remoteParticipantCount;
  final int meetingDurationSeconds;
  final int timeRemainingSeconds;
  final bool isScreenSharing;

  /// True when the user has backed out of the call screen while the call is
  /// still live (e.g., to show content they are screen-sharing).
  final bool isMinimized;

  const CallUiState({
    this.phase = CallPhase.idle,
    this.callRoom,
    this.errorMessage,
    this.localVideoTrack,
    this.remoteVideoTrack,
    this.remoteScreenShareTrack,
    this.cameraEnabled = true,
    this.micEnabled = true,
    this.frontCamera = true,
    this.chatMessages = const [],
    this.showChat = false,
    this.isRemoteTyping = false,
    this.remoteTypingUsername = '',
    this.callDuration = Duration.zero,
    this.remoteParticipantCount = 0,
    this.meetingDurationSeconds = 0,
    this.timeRemainingSeconds = 0,
    this.isScreenSharing = false,
    this.isMinimized = false,
  });

  // ── Derived ──────────────────────────────────────────────────────────────────
  bool get isLoading => phase == CallPhase.loading;
  bool get isConnected => phase == CallPhase.connected;
  bool get hasError => phase == CallPhase.error;
  bool get hasTimeLimit => meetingDurationSeconds > 0;
  bool get isTimeWarning =>
      hasTimeLimit && timeRemainingSeconds > 0 && timeRemainingSeconds <= 60;

  /// True when the remote participant is sharing their screen.
  bool get isRemoteScreenSharing => remoteScreenShareTrack != null;

  String get formattedDuration {
    final h = callDuration.inHours;
    final m = callDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = callDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String get formattedTimeRemaining {
    final t = timeRemainingSeconds.clamp(0, meetingDurationSeconds);
    final h = t ~/ 3600;
    final m = ((t % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (t % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── copyWith ─────────────────────────────────────────────────────────────────
  CallUiState copyWith({
    CallPhase? phase,
    CallRoom? callRoom,
    String? errorMessage,
    LocalVideoTrack? localVideoTrack,
    bool clearLocalVideo = false,
    VideoTrack? remoteVideoTrack,
    bool clearRemoteVideo = false,
    VideoTrack? remoteScreenShareTrack,
    bool clearRemoteScreenShare = false,
    bool? cameraEnabled,
    bool? micEnabled,
    bool? frontCamera,
    List<CallChatMessage>? chatMessages,
    bool? showChat,
    bool? isRemoteTyping,
    String? remoteTypingUsername,
    Duration? callDuration,
    int? remoteParticipantCount,
    int? meetingDurationSeconds,
    int? timeRemainingSeconds,
    bool? isScreenSharing,
    bool? isMinimized,
  }) {
    return CallUiState(
      phase: phase ?? this.phase,
      callRoom: callRoom ?? this.callRoom,
      errorMessage: errorMessage ?? this.errorMessage,
      localVideoTrack:
          clearLocalVideo ? null : (localVideoTrack ?? this.localVideoTrack),
      remoteVideoTrack:
          clearRemoteVideo ? null : (remoteVideoTrack ?? this.remoteVideoTrack),
      remoteScreenShareTrack: clearRemoteScreenShare
          ? null
          : (remoteScreenShareTrack ?? this.remoteScreenShareTrack),
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      micEnabled: micEnabled ?? this.micEnabled,
      frontCamera: frontCamera ?? this.frontCamera,
      chatMessages: chatMessages ?? this.chatMessages,
      showChat: showChat ?? this.showChat,
      isRemoteTyping: isRemoteTyping ?? this.isRemoteTyping,
      remoteTypingUsername: remoteTypingUsername ?? this.remoteTypingUsername,
      callDuration: callDuration ?? this.callDuration,
      remoteParticipantCount:
          remoteParticipantCount ?? this.remoteParticipantCount,
      meetingDurationSeconds:
          meetingDurationSeconds ?? this.meetingDurationSeconds,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class CallNotifier extends Notifier<CallUiState> {
  final _api = CallApiService();
  final _chatService = CallChatService();

  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  Timer? _durationTimer;
  Timer? _typingTimer;
  int _currentUserId = 0;

  // Stored so we can re-open the CallScreen after minimizing.
  String? _authToken;
  String? _currentUserName;
  int _meetingDurationMinutes = 0;

  /// Parameters needed to re-push the CallScreen when returning from minimize.
  ({
    String roomId,
    String authToken,
    int currentUserId,
    String currentUserName,
    int meetingDurationMinutes,
  })? get callScreenParams {
    final room = state.callRoom;
    if (room == null || _authToken == null) return null;
    return (
      roomId: room.id,
      authToken: _authToken!,
      currentUserId: _currentUserId,
      currentUserName: _currentUserName ?? '',
      meetingDurationMinutes: _meetingDurationMinutes,
    );
  }

  @override
  CallUiState build() {
    ref.onDispose(_cleanup);
    return const CallUiState();
  }

  // ── Join ──────────────────────────────────────────────────────────────────
  Future<void> joinCall({
    required String roomId,
    required String authToken,
    required int currentUserId,
    bool initialCameraEnabled = true,
    bool initialMicEnabled = true,
    int meetingDurationMinutes = 0,
  }) async {
    // Already in a live call (e.g. returning from minimized state). Skip.
    if (state.phase == CallPhase.connected || state.phase == CallPhase.loading) {
      state = state.copyWith(isMinimized: false);
      return;
    }

    _currentUserId = currentUserId;
    _authToken = authToken;
    _currentUserName = null;
    _meetingDurationMinutes = meetingDurationMinutes;

    // Full reset for a fresh call.
    state = CallUiState(
      phase: CallPhase.loading,
      cameraEnabled: initialCameraEnabled,
      micEnabled: initialMicEnabled,
    );

    try {
      // ── 1. Fetch room from backend ────────────────────────────────────────
      final CallRoom callRoom;
      try {
        callRoom = await _api.getRoom(roomId);
      } on DioException catch (e) {
        // DioException(connectionError) covers SocketException scenarios too.
        _fail(_dioErrorMessage(e));
        return;
      } on TimeoutException {
        _fail('Request timed out. Please try again.');
        return;
      } catch (e) {
        _fail('Could not reach the server. Check your connection.');
        return;
      }

      if (state.phase == CallPhase.error) return; // already failed

      if (!callRoom.canJoin) {
        _fail('This call is not available right now.');
        return;
      }
      if (callRoom.livekitToken == null || callRoom.livekitUrl == null) {
        _fail('Could not obtain call credentials. Please try again.');
        return;
      }

      // ── 2. Load chat history (non-fatal) ──────────────────────────────────
      final history = <CallChatMessage>[];
      try {
        final raw = await _api.getMessages(roomId);
        history.addAll(
          raw.map((j) => CallChatMessage.fromJson(j, currentUserId)),
        );

        print(history);
      } catch (_) {}

      if (state.phase == CallPhase.error) return;

      // ── 3. WebSocket chat ─────────────────────────────────────────────────
      try {
        _chatService.connect(
          roomId: roomId,
          token: authToken,
          onMessage: _onWsMessage,
          onTyping: _onWsTyping,
          onCallEnded: _onRemoteEndedCall,
          onError: (_) {},
          onDone: () {},
        );
      } catch (e) {
        // Chat WebSocket failure is non-fatal — call can proceed without it.
        debugPrint('[Call] WebSocket connect error: $e');
      }

      // ── 4. LiveKit room ───────────────────────────────────────────────────
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 24,
            params: VideoParametersPresets.h360_169,
          ),
          defaultVideoPublishOptions: VideoPublishOptions(
            simulcast: false,
          ),
        ),
      );

      _roomListener = _room!.createListener()
        ..on<TrackSubscribedEvent>(_onTrackSubscribed)
        ..on<TrackUnsubscribedEvent>(_onTrackUnsubscribed)
        ..on<ParticipantConnectedEvent>((_) => _syncParticipants())
        ..on<ParticipantDisconnectedEvent>((_) {
          _syncParticipants();
          _onRemoteParticipantLeft();
        })
        ..on<RoomDisconnectedEvent>(_onRoomDisconnected)
        ..on<LocalTrackPublishedEvent>((_) => _syncLocalVideo())
        ..on<LocalTrackUnpublishedEvent>((_) => _syncLocalVideo());

      try {
        await _room!.connect(callRoom.livekitUrl!, callRoom.livekitToken!);
      } on TimeoutException {
        _fail('Connection to call server timed out. Please try again.');
        return;
      } catch (e) {
        _fail('Failed to join the call: ${_simplifyError(e)}');
        return;
      }

      if (state.phase == CallPhase.error) return;

      // ── 5. Enable local tracks ────────────────────────────────────────────
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(initialMicEnabled);
      } catch (e) {
        debugPrint('[Call] setMicrophoneEnabled error: $e');
        state = state.copyWith(micEnabled: false);
      }

      try {
        await _room!.localParticipant?.setCameraEnabled(initialCameraEnabled);
      } catch (e) {
        debugPrint('[Call] setCameraEnabled error: $e');
        state = state.copyWith(cameraEnabled: false);
      }

      _syncLocalVideo();

      // Attach any remote tracks already present (e.g. on rejoin).
      for (final p in _room!.remoteParticipants.values) {
        _attachRemote(p);
      }

      // ── 6. Start duration timer ───────────────────────────────────────────
      final totalDurationSecs = meetingDurationMinutes * 60;
      int remainingSecs = totalDurationSecs;
      if (totalDurationSecs > 0 && callRoom.scheduledEnd != null) {
        final diff =
            callRoom.scheduledEnd!.toLocal().difference(DateTime.now()).inSeconds;
        remainingSecs = diff.clamp(0, totalDurationSecs);
      }

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.phase != CallPhase.connected) return;
        final newElapsed = state.callDuration + const Duration(seconds: 1);
        if (state.hasTimeLimit) {
          final newRemaining = state.timeRemainingSeconds - 1;
          if (newRemaining <= 0) {
            state = state.copyWith(
              callDuration: newElapsed,
              timeRemainingSeconds: 0,
            );
            _autoEndCall();
          } else {
            state = state.copyWith(
              callDuration: newElapsed,
              timeRemainingSeconds: newRemaining,
            );
          }
        } else {
          state = state.copyWith(callDuration: newElapsed);
        }
      });

      // Derive and store the current user's display name from the room data.
      _currentUserName = callRoom.user.id == currentUserId
          ? callRoom.user.fullName
          : callRoom.advisor.fullName;

      state = state.copyWith(
        phase: CallPhase.connected,
        callRoom: callRoom,
        chatMessages: history,
        remoteParticipantCount: _room!.remoteParticipants.length,
        meetingDurationSeconds: totalDurationSecs,
        timeRemainingSeconds: remainingSecs,
      );
    } catch (e) {
      debugPrint('[Call] joinCall unexpected error: $e');
      _fail('Could not start the call. Please try again.');
    }
  }

  // ── LiveKit event handlers ────────────────────────────────────────────────

  /// Handles the LiveKit room being disconnected unexpectedly (network drop,
  /// server-side kick, etc.).
  void _onRoomDisconnected(RoomDisconnectedEvent e) {
    if (state.phase != CallPhase.connected) return;
    debugPrint('[Call] Room disconnected: ${e.reason}');
    _cleanup();
    state = state.copyWith(phase: CallPhase.ended);
  }

  /// Keeps only the camera publication in localVideoTrack — screen share is
  /// a separate publication and must not replace the PiP self-view.
  void _syncLocalVideo() {
    try {
      final cameraPubs = _room?.localParticipant?.videoTrackPublications
              .where((pub) => pub.source == TrackSource.camera) ??
          const Iterable.empty();
      final track = cameraPubs.isEmpty ? null : cameraPubs.first.track;
      state = track != null
          ? state.copyWith(localVideoTrack: track)
          : state.copyWith(clearLocalVideo: true);
    } catch (e) {
      debugPrint('[Call] _syncLocalVideo error: $e');
    }
  }

  void _syncParticipants() {
    try {
      state = state.copyWith(
        remoteParticipantCount: _room?.remoteParticipants.length ?? 0,
      );
    } catch (e) {
      debugPrint('[Call] _syncParticipants error: $e');
    }
  }

  /// Routes the subscribed track to the correct state slot based on its
  /// source — screen share goes to remoteScreenShareTrack, camera to
  /// remoteVideoTrack.
  void _onTrackSubscribed(TrackSubscribedEvent e) {
    try {
      if (e.track is! VideoTrack) return;
      final track = e.track as VideoTrack;
      if (e.publication.source == TrackSource.screenShareVideo) {
        state = state.copyWith(remoteScreenShareTrack: track);
      } else {
        state = state.copyWith(remoteVideoTrack: track);
      }
    } catch (e) {
      debugPrint('[Call] _onTrackSubscribed error: $e');
    }
  }

  void _onTrackUnsubscribed(TrackUnsubscribedEvent e) {
    try {
      if (e.publication.source == TrackSource.screenShareVideo) {
        if (e.track == state.remoteScreenShareTrack) {
          state = state.copyWith(clearRemoteScreenShare: true);
        }
      } else {
        if (e.track == state.remoteVideoTrack) {
          state = state.copyWith(clearRemoteVideo: true);
        }
      }
    } catch (e) {
      debugPrint('[Call] _onTrackUnsubscribed error: $e');
    }
  }

  /// Subscribes to ALL video publications of a remote participant.
  void _attachRemote(RemoteParticipant p) {
    try {
      for (final pub in p.videoTrackPublications) {
        try {
          if (!pub.subscribed) pub.subscribe();
        } catch (_) {}
        final track = pub.track;
        if (track == null) continue;
        // videoTrackPublications always contain VideoTrack instances.
        final videoTrack = track as VideoTrack;
        if (pub.source == TrackSource.screenShareVideo) {
          state = state.copyWith(remoteScreenShareTrack: videoTrack);
        } else {
          state = state.copyWith(remoteVideoTrack: videoTrack);
        }
      }
    } catch (e) {
      debugPrint('[Call] _attachRemote error: $e');
    }
  }

  // ── WebSocket event handlers ──────────────────────────────────────────────
  void _onWsMessage(Map<String, dynamic> data) {
    try {
      final msg = CallChatMessage.fromWsData(
        data: data,
        currentUserId: _currentUserId,
      );
      // Dedup: skip if we already have a message with the same ID (e.g. the
      // sender already added it via addFileMessage before the WS echo arrives).
      if (_isDuplicate(msg)) return;
      state = state.copyWith(chatMessages: [...state.chatMessages, msg]);
    } catch (e) {
      debugPrint('[Call] _onWsMessage parse error: $e');
    }
  }

  bool _isDuplicate(CallChatMessage incoming) {
    if (incoming.id != null) {
      return state.chatMessages.any((m) => m.id == incoming.id);
    }
    // Fallback for messages without IDs: match sender + url + close timestamp.
    return state.chatMessages.any((m) =>
        m.senderId == incoming.senderId &&
        m.fileUrl == incoming.fileUrl &&
        m.fileUrl != null &&
        m.timestamp.difference(incoming.timestamp).abs() < const Duration(seconds: 10));
  }

  void _onWsTyping(Map<String, dynamic> data) {
    try {
      _typingTimer?.cancel();
      final isTyping = data['is_typing'] == true;
      state = state.copyWith(
        isRemoteTyping: isTyping,
        remoteTypingUsername: data['sender_username'] ?? '',
      );
      if (isTyping) {
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (state.phase == CallPhase.connected) {
            state = state.copyWith(isRemoteTyping: false);
          }
        });
      }
    } catch (e) {
      debugPrint('[Call] _onWsTyping error: $e');
    }
  }

  // ── Controls ─────────────────────────────────────────────────────────────
  Future<void> toggleMic() async {
    final next = !state.micEnabled;
    state = state.copyWith(micEnabled: next);
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(next);
    } catch (e) {
      debugPrint('[Call] toggleMic error: $e');
      // Revert the optimistic UI update on failure.
      state = state.copyWith(micEnabled: !next);
    }
  }

  Future<void> toggleCamera() async {
    final next = !state.cameraEnabled;
    state = state.copyWith(cameraEnabled: next);
    try {
      await _room?.localParticipant?.setCameraEnabled(next);
      _syncLocalVideo();
    } catch (e) {
      debugPrint('[Call] toggleCamera error: $e');
      state = state.copyWith(cameraEnabled: !next);
    }
  }

  Future<void> flipCamera() async {
    if (!state.cameraEnabled) return;
    final front = !state.frontCamera;
    final pos = front ? CameraPosition.front : CameraPosition.back;
    try {
      final cameraPub = _room?.localParticipant?.videoTrackPublications
          .where((pub) => pub.source == TrackSource.camera)
          .firstOrNull;
      final track = cameraPub?.track;
      if (track is LocalVideoTrack) {
        await track.restartTrack(CameraCaptureOptions(cameraPosition: pos));
        state = state.copyWith(frontCamera: front);
        _syncLocalVideo();
      }
    } catch (e) {
      debugPrint('[Call] flipCamera error: $e');
    }
  }

  Future<void> toggleScreenShare() async {
    if (state.isScreenSharing) {
      await _stopScreenShare();
    } else {
      await _startScreenShare();
    }
  }

  Future<void> _startScreenShare() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final permitted = await Helper.requestCapturePermission();
        if (!permitted) return;

        const androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: 'Screen Sharing',
          notificationText: 'You are sharing your screen',
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon:
              AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        );
        try {
          final ok =
              await FlutterBackground.initialize(androidConfig: androidConfig);
          if (ok) await FlutterBackground.enableBackgroundExecution();
        } catch (e) {
          debugPrint('[Call] FlutterBackground init error: $e');
          // Non-fatal — attempt screen share anyway.
        }
      }

      await _room?.localParticipant?.setScreenShareEnabled(true);
      state = state.copyWith(isScreenSharing: true);
    } catch (e) {
      debugPrint('[Call] _startScreenShare error: $e');
      state = state.copyWith(isScreenSharing: false);
      _disableAndroidBackground();
    }
  }

  Future<void> _stopScreenShare() async {
    try {
      await _room?.localParticipant?.setScreenShareEnabled(false);
    } catch (e) {
      debugPrint('[Call] _stopScreenShare error: $e');
    } finally {
      state = state.copyWith(isScreenSharing: false);
      _disableAndroidBackground();
    }
  }

  void _disableAndroidBackground() {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        FlutterBackground.disableBackgroundExecution();
      }
    } catch (_) {}
  }

  void toggleChat() => state = state.copyWith(showChat: !state.showChat);

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    try {
      _chatService.sendMessage(text.trim());
    } catch (e) {
      debugPrint('[Call] sendChatMessage error: $e');
    }
  }

  void sendTyping(bool isTyping) {
    try {
      _chatService.sendTyping(isTyping);
    } catch (e) {
      debugPrint('[Call] sendTyping error: $e');
    }
  }

  void addFileMessage(Map<String, dynamic> data) {
    try {
      debugPrint('[Call] addFileMessage raw data: $data');
      final msg = CallChatMessage.fromJson(data, _currentUserId);
      debugPrint('[Call] addFileMessage parsed: isFile=${msg.isFile} fileUrl=${msg.fileUrl} isMe=${msg.isMe}');
      state = state.copyWith(chatMessages: [...state.chatMessages, msg]);

      // Broadcast to the receiver via WebSocket so they see it instantly.
      // The server does not send a WS push for HTTP file uploads.
      if (msg.isFile && msg.fileUrl != null) {
        _chatService.sendFileMessage(
          messageId: msg.id,
          fileUrl: msg.fileUrl!,
          fileName: msg.fileName ?? '',
          senderId: _currentUserId,
          senderUsername: _currentUserName ?? '',
          text: msg.text,
        );
      }
    } catch (e) {
      debugPrint('[Call] addFileMessage error: $e');
    }
  }

  // ── Minimize / restore ───────────────────────────────────────────────────
  /// User backed out of the call screen during screen share — call stays live.
  void minimizeCall() => state = state.copyWith(isMinimized: true);

  /// User returned to the call screen — clear the minimized flag.
  void unMinimizeCall() => state = state.copyWith(isMinimized: false);

  // ── End / Error ───────────────────────────────────────────────────────────
  Future<void> _autoEndCall() async {
    if (state.phase == CallPhase.ended) return;
    final roomId = state.callRoom?.id;
    _cleanup();
    state = state.copyWith(phase: CallPhase.ended);
    if (roomId != null) {
      try {
        await _api.endCall(roomId);
      } catch (_) {}
    }
  }

  Future<void> endCall(String roomId) async {
    if (state.phase == CallPhase.ended) return;
    try {
      _chatService.sendCallEnded();
    } catch (_) {}
    _cleanup();
    state = state.copyWith(phase: CallPhase.ended);
    try {
      await _api.endCall(roomId);
    } catch (_) {}
  }

  /// Called when the remote participant disconnects from the LiveKit room.
  /// If the call was active and no remote participants remain, end locally.
  void _onRemoteParticipantLeft() {
    try {
      if (state.phase != CallPhase.connected) return;
      if (_room?.remoteParticipants.isEmpty ?? true) {
        _cleanup();
        state = state.copyWith(phase: CallPhase.ended);
      }
    } catch (e) {
      debugPrint('[Call] _onRemoteParticipantLeft error: $e');
    }
  }

  /// Called when the other user sends a `call_ended` WebSocket message.
  void _onRemoteEndedCall() {
    try {
      if (state.phase == CallPhase.ended) return;
      _cleanup();
      state = state.copyWith(phase: CallPhase.ended);
    } catch (e) {
      debugPrint('[Call] _onRemoteEndedCall error: $e');
    }
  }

  void _fail(String msg) {
    _cleanup();
    state = state.copyWith(phase: CallPhase.error, errorMessage: msg);
  }

  /// Synchronous cleanup — all operations individually guarded so a failure
  /// in one step never prevents the others from running.
  void _cleanup() {
    if (_room == null) return;
    _durationTimer?.cancel();
    _durationTimer = null;
    _typingTimer?.cancel();
    _typingTimer = null;
    try {
      _roomListener?.dispose();
    } catch (_) {}
    _roomListener = null;
    try {
      _chatService.disconnect();
    } catch (_) {}
    final room = _room;
    _room = null;
    // Fire-and-forget disconnect so cleanup stays synchronous.
    // unawaited is intentional — errors are silently swallowed.
    room?.disconnect().catchError((_) {});
    _disableAndroidBackground();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Converts a [DioException] into a user-readable sentence.
  String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) return 'Access denied. Please sign in again.';
        if (code == 404) return 'Call not found. It may have already ended.';
        if (code != null && code >= 500) return 'Server error. Please try again later.';
        return 'Unexpected server response ($code).';
      default:
        return 'Network error. Please try again.';
    }
  }

  /// Strips internal class names and stack-trace noise from arbitrary errors.
  String _simplifyError(Object e) {
    final msg = e.toString();
    // LiveKit wraps errors in 'Exception(...)' or 'Error(...)' patterns.
    final match = RegExp(r'Exception\((.+?)\)|Error\((.+?)\)').firstMatch(msg);
    if (match != null) return match.group(1) ?? match.group(2) ?? msg;
    if (msg.length > 120) return '${msg.substring(0, 120)}…';
    return msg;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final callNotifierProvider = NotifierProvider<CallNotifier, CallUiState>(
  CallNotifier.new,
);
