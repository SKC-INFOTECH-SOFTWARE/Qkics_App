import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool loop;
  final double? aspectRatio;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool mute;

  /// Called once, after the video has initialized, with its natural
  /// (width / height) aspect ratio.
  final ValueChanged<double>? onAspectRatioResolved;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.loop = true,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.onTap,
    this.mute = false,
    this.onAspectRatioResolved,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // Dispose of the previous controller if it exists
    if (_initialized || _error != null) {
      // Check if a controller was previously initialized or attempted
      _controller.dispose();
    }

    setState(() {
      _error = null;
      _initialized = false;
    });

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
            });
            if (widget.autoPlay) {
              _controller.play();
              _controller.setVolume(widget.mute ? 0 : 1.0);
            }
            final size = _controller.value.size;
            if (size.height > 0) {
              widget.onAspectRatioResolved?.call(size.width / size.height);
            }
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
            });
          }
        });

    _controller.setLooping(widget.loop);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      if (_controller.value.volume == 0) {
        _controller.setVolume(1.0);
      } else {
        _controller.setVolume(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text(
                "Playback Error",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _initializeController,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget player = SizedBox.expand(
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );

    if (widget.aspectRatio != null) {
      player = AspectRatio(aspectRatio: widget.aspectRatio!, child: player);
    }

    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction == 0) {
          if (_controller.value.isPlaying) {
            _controller.pause();
            setState(() {});
          }
        } else if (info.visibleFraction > 0.8 && widget.autoPlay) {
          if (!_controller.value.isPlaying) {
            _controller.play();
            setState(() {});
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            setState(() {
              _showControls = !_showControls;
            });
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            player,
            if (_showControls) ...[
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: IconButton(
                      iconSize: 50,
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlay,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    _controller.value.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
