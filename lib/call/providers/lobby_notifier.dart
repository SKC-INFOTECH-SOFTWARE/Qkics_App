import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

// ─────────────────────────────────────────────────────────────────────────────
// Immutable lobby state
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class LobbyState {
  final LocalVideoTrack? previewTrack;
  final bool cameraOn;
  final bool micOn;
  final bool isLoading;
  final bool toggling; // debounce rapid camera taps
  final bool joining;

  const LobbyState({
    this.previewTrack,
    this.cameraOn = true,
    this.micOn = true,
    this.isLoading = true,
    this.toggling = false,
    this.joining = false,
  });

  LobbyState copyWith({
    LocalVideoTrack? previewTrack,
    bool clearPreview = false,
    bool? cameraOn,
    bool? micOn,
    bool? isLoading,
    bool? toggling,
    bool? joining,
  }) {
    return LobbyState(
      previewTrack:
          clearPreview ? null : (previewTrack ?? this.previewTrack),
      cameraOn: cameraOn ?? this.cameraOn,
      micOn: micOn ?? this.micOn,
      isLoading: isLoading ?? this.isLoading,
      toggling: toggling ?? this.toggling,
      joining: joining ?? this.joining,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class LobbyNotifier extends AutoDisposeNotifier<LobbyState> {
  @override
  LobbyState build() {
    // Stop preview track automatically when lobby is disposed (back button).
    ref.onDispose(() => state.previewTrack?.stop());
    return const LobbyState();
  }

  Future<void> initPreview() async {
    // permission_handler only works on mobile. On web the browser prompts
    // for camera/mic access when WebRTC opens the track.
    if (_isMobilePlatform) {
      final statuses =
          await [Permission.camera, Permission.microphone].request();
      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      if (!cameraGranted) {
        state = state.copyWith(cameraOn: false, isLoading: false);
        return;
      }
    }

    try {
      final track = await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(cameraPosition: CameraPosition.front),
      );
      state = state.copyWith(previewTrack: track, isLoading: false);
    } catch (_) {
      state = state.copyWith(cameraOn: false, isLoading: false);
    }
  }

  Future<void> toggleCamera() async {
    if (state.toggling) return;
    state = state.copyWith(toggling: true);
    try {
      if (state.cameraOn) {
        await state.previewTrack?.stop();
        state = state.copyWith(clearPreview: true, cameraOn: false);
      } else {
        try {
          final track = await LocalVideoTrack.createCameraTrack(
            const CameraCaptureOptions(cameraPosition: CameraPosition.front),
          );
          state = state.copyWith(previewTrack: track, cameraOn: true);
        } catch (_) {}
      }
    } finally {
      state = state.copyWith(toggling: false);
    }
  }

  void toggleMic() => state = state.copyWith(micOn: !state.micOn);

  /// Stops the preview track and marks as joining.
  /// Returns once the hardware camera is fully released.
  Future<void> prepareJoin() async {
    state = state.copyWith(joining: true);
    final track = state.previewTrack;
    state = state.copyWith(clearPreview: true);
    await track?.stop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final lobbyNotifierProvider =
    NotifierProvider.autoDispose<LobbyNotifier, LobbyState>(
  LobbyNotifier.new,
);
