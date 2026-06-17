import 'dart:io';
import 'dart:math' show max;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ─── Isolate helpers (must be top-level for compute()) ───────────────────────

class _CropParams {
  final Uint8List imageBytes;
  final double userScale;
  final double userOffsetDx;
  final double userOffsetDy;
  final double frameWidth;
  final double frameHeight;
  final String outputPath;

  const _CropParams({
    required this.imageBytes,
    required this.userScale,
    required this.userOffsetDx,
    required this.userOffsetDy,
    required this.frameWidth,
    required this.frameHeight,
    required this.outputPath,
  });
}

/// Runs entirely in a background isolate — no platform channels used.
Future<void> _cropImageIsolate(_CropParams p) async {
  final srcImg = img.decodeImage(p.imageBytes);
  if (srcImg == null) throw Exception('Could not decode image');

  final srcW = srcImg.width.toDouble();
  final srcH = srcImg.height.toDouble();

  final fw = p.frameWidth > 0 ? p.frameWidth : srcW;
  final fh = p.frameHeight > 0 ? p.frameHeight : srcH;

  final coverScale = max(fw / srcW, fh / srcH);
  final totalScale = coverScale * p.userScale;

  final cropW = (fw / totalScale).clamp(1.0, srcW);
  final cropH = (fh / totalScale).clamp(1.0, srcH);
  final baseSrcX = (srcW - cropW) / 2;
  final baseSrcY = (srcH - cropH) / 2;
  final srcX = (baseSrcX - p.userOffsetDx / totalScale)
      .clamp(0.0, (srcW - cropW).clamp(0.0, srcW));
  final srcY = (baseSrcY - p.userOffsetDy / totalScale)
      .clamp(0.0, (srcH - cropH).clamp(0.0, srcH));

  final cropped = img.copyCrop(
    srcImg,
    x: srcX.toInt(),
    y: srcY.toInt(),
    width: cropW.toInt().clamp(1, srcImg.width),
    height: cropH.toInt().clamp(1, srcImg.height),
  );

  final jpegBytes = img.encodeJpg(cropped, quality: 90);
  await File(p.outputPath).writeAsBytes(jpegBytes);
}

enum PostAspectRatio {
  square(label: '1:1', ratio: 1.0, icon: Icons.crop_square),
  portrait(label: '4:5', ratio: 4.0 / 5.0, icon: Icons.crop_portrait),
  landscape(label: '16:9', ratio: 16.0 / 9.0, icon: Icons.crop_landscape);

  const PostAspectRatio({
    required this.label,
    required this.ratio,
    required this.icon,
  });

  final String label;
  final double ratio;
  final IconData icon;
}

class ImageRatioSelectorSheet extends StatefulWidget {
  final List<File> images;

  const ImageRatioSelectorSheet({super.key, required this.images});

  @override
  State<ImageRatioSelectorSheet> createState() =>
      _ImageRatioSelectorSheetState();
}

class _ImageRatioSelectorSheetState extends State<ImageRatioSelectorSheet> {
  PostAspectRatio _ratio = PostAspectRatio.square;
  int _previewIndex = 0;
  bool _isCropping = false;

  // Per-image pan offset (screen pixels from the frame center).
  late final List<Offset> _offsets;
  // Per-image zoom level. 1.0 = fills frame (cover), max 4.0.
  late final List<double> _scales;
  // Source image dimensions (decoded once, used for overflow math + crop).
  late final List<ui.Size?> _srcSizes;

  // Set by LayoutBuilder on every build — used in _cropImage.
  Size _frameSize = Size.zero;

  // Gesture tracking state (reset on each gesture start).
  double _gestureStartScale = 1.0;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  @override
  void initState() {
    super.initState();
    final n = widget.images.length;
    _offsets = List<Offset>.filled(n, Offset.zero);
    _scales = List<double>.filled(n, 1.0);
    _srcSizes = List<ui.Size?>.filled(n, null);
    _loadSrcSizes();
  }

  Future<void> _loadSrcSizes() async {
    for (int i = 0; i < widget.images.length; i++) {
      final bytes = await widget.images[i].readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _srcSizes[i] = ui.Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
        });
      }
    }
  }

  // ─── Gesture ─────────────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d, int imgIndex) {
    _gestureStartScale = _scales[imgIndex];
    _gestureStartOffset = _offsets[imgIndex];
    _gestureStartFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size frameSize, int imgIndex) {
    final src = _srcSizes[imgIndex];
    if (src == null) return;

    // New zoom clamped to [1.0, 4.0].
    final newUserScale = (_gestureStartScale * d.scale).clamp(1.0, 4.0);

    // Display size of the image at this zoom.
    final coverScale = max(
      frameSize.width / src.width,
      frameSize.height / src.height,
    );
    final dispW = src.width * coverScale * newUserScale;
    final dispH = src.height * coverScale * newUserScale;

    // Max pan before empty space shows.
    final maxOffX = max(0.0, (dispW - frameSize.width) / 2);
    final maxOffY = max(0.0, (dispH - frameSize.height) / 2);

    // Keep the content under the focal point fixed as scale + pan change.
    //   newOffset = focalPoint − frameCenter
    //             − (startFocal − frameCenter − startOffset) × newScale/startScale
    final frameCenter = Offset(frameSize.width / 2, frameSize.height / 2);
    final scaleRatio = newUserScale / _gestureStartScale;
    final rawOffset =
        d.localFocalPoint -
        frameCenter -
        (_gestureStartFocal - frameCenter - _gestureStartOffset) * scaleRatio;

    setState(() {
      _scales[imgIndex] = newUserScale;
      _offsets[imgIndex] = Offset(
        rawOffset.dx.clamp(-maxOffX, maxOffX),
        rawOffset.dy.clamp(-maxOffY, maxOffY),
      );
    });
  }

  // ─── Crop ────────────────────────────────────────────────────────────────────

  Future<List<File>> _cropAll() async {
    final results = <File>[];
    for (int i = 0; i < widget.images.length; i++) {
      results.add(await _cropImage(widget.images[i], i));
    }
    return results;
  }

  Future<File> _cropImage(File imageFile, int index) async {
    // Read bytes and resolve the output path on the main isolate
    // (platform channels like getTemporaryDirectory are not available in isolates).
    final srcBytes = await imageFile.readAsBytes();
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/crop_${DateTime.now().microsecondsSinceEpoch}.jpg';

    // Offload all CPU-heavy work (decode → crop → encode) to a background isolate
    // so the main thread stays free and the UI never jank-freezes.
    await compute(
      _cropImageIsolate,
      _CropParams(
        imageBytes: srcBytes,
        userScale: _scales[index],
        userOffsetDx: _offsets[index].dx,
        userOffsetDy: _offsets[index].dy,
        frameWidth: _frameSize.width,
        frameHeight: _frameSize.height,
        outputPath: outputPath,
      ),
    );

    return File(outputPath);
  }

  // ─── Preview widget ───────────────────────────────────────────────────────────

  Widget _buildPreview(Size frameSize) {
    // Always keep _frameSize in sync for crop.
    _frameSize = frameSize;

    final i = _previewIndex;
    final src = _srcSizes[i];

    // While dimensions are loading, show the image unzoomed as a placeholder.
    if (src == null) {
      return ClipRect(
        child: Image.file(
          widget.images[i],
          fit: BoxFit.cover,
          width: frameSize.width,
          height: frameSize.height,
        ),
      );
    }

    final coverScale = max(
      frameSize.width / src.width,
      frameSize.height / src.height,
    );
    final dispW = src.width * coverScale * _scales[i];
    final dispH = src.height * coverScale * _scales[i];

    final maxOffX = max(0.0, (dispW - frameSize.width) / 2);
    final maxOffY = max(0.0, (dispH - frameSize.height) / 2);
    final clampedOffset = Offset(
      _offsets[i].dx.clamp(-maxOffX, maxOffX),
      _offsets[i].dy.clamp(-maxOffY, maxOffY),
    );

    // Top-left position of the image inside the frame.
    final imgLeft = (frameSize.width - dispW) / 2 + clampedOffset.dx;
    final imgTop = (frameSize.height - dispH) / 2 + clampedOffset.dy;

    return GestureDetector(
      onScaleStart: (d) => _onScaleStart(d, i),
      onScaleUpdate: (d) => _onScaleUpdate(d, frameSize, i),
      child: SizedBox(
        width: frameSize.width,
        height: frameSize.height,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: imgLeft,
                top: imgTop,
                width: dispW,
                height: dispH,
                child: Image.file(
                  widget.images[i],
                  width: dispW,
                  height: dispH,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),
              // Hint: visible only while user hasn't zoomed.
              if (_scales[i] == 1.0)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_with,
                              color: Colors.white70,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Drag or pinch to adjust',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Text(
                  'Adjust Frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: _isCropping
                      ? null
                      : () async {
                          setState(() => _isCropping = true);
                          try {
                            final cropped = await _cropAll();
                            if (context.mounted) {
                              Navigator.pop(context, cropped);
                            }
                          } catch (e) {
                            debugPrint('Crop error: $e');
                            if (context.mounted) {
                              setState(() => _isCropping = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to process image. Try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: _isCropping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // ── Pannable / zoomable image preview ────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: AspectRatio(
                  aspectRatio: _ratio.ratio,
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => _buildPreview(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Zoom indicator ────────────────────────────────────────────────────
          if (_scales[_previewIndex] > 1.0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_scales[_previewIndex].toStringAsFixed(1)}×',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() {
                      _scales[_previewIndex] = 1.0;
                      _offsets[_previewIndex] = Offset.zero;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Thumbnail strip (multi-image) ─────────────────────────────────────
          if (widget.images.length > 1)
            SizedBox(
              height: 68,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                itemCount: widget.images.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _previewIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 54,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _previewIndex == i
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(widget.images[i], fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),

          // ── Ratio selector buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: PostAspectRatio.values.map((r) {
                final selected = _ratio == r;
                return GestureDetector(
                  onTap: () => setState(() {
                    _ratio = r;
                    // Reset pan + zoom for all images — overflow changes with ratio.
                    for (int i = 0; i < widget.images.length; i++) {
                      _offsets[i] = Offset.zero;
                      _scales[i] = 1.0;
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          r.icon,
                          size: 18,
                          color: selected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.label,
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
