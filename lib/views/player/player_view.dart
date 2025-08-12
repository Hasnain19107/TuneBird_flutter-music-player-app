import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../viewmodels/music_viewmodel.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';
import '../../services/artwork_cache_service.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Get.back(),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              // Navigate to playlist
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Glassy background derived from artwork colors
          const _ArtworkColorBackground(),
          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
            // Album Art
            Obx(() {
              final song = viewModel.currentSong;
              Future<File?> futureFile;
              if (song != null) {
                final id = int.tryParse(song.id);
                if (id != null) {
                  futureFile = ArtworkCacheService.getCachedFile(id);
                } else if (song.uri.isNotEmpty) {
                  futureFile = ArtworkCacheService.getCachedFileForPath(song.uri);
                } else {
                  futureFile = Future.value(null);
                }
              } else {
                futureFile = Future.value(null);
              }
              return FutureBuilder<File?>(
                future: futureFile,
                builder: (context, snapshot) {
                  final cached = snapshot.data;
                  Widget content;
                  if (cached != null) {
                    content = Image.file(cached, fit: BoxFit.cover);
                  } else if (song != null) {
                    final id = int.tryParse(song.id);
                    if (id != null) {
                      content = QueryArtworkWidget(
                        id: id,
                        type: ArtworkType.AUDIO,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: const Icon(Icons.music_note, size: 80),
                      );
                      // ignore: unawaited_futures
                      ArtworkCacheService.ensureCached(id);
                    } else if (song.uri.isNotEmpty) {
                      content = const Icon(Icons.music_note, size: 80);
                      // Warm up path-based cache
                      // ignore: unawaited_futures
                      ArtworkCacheService.ensureCachedForPath(song.uri);
                    } else {
                      content = const Icon(Icons.music_note, size: 80);
                    }
                  } else {
                    content = const Icon(Icons.music_note, size: 80);
                  }
                  return Container(
                    width: Get.width * 0.78,
                    height: Get.width * 0.78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: content,
                  );
                },
              );
            }),

            // Song Info
            Column(
              children: [
                Obx(() => _MarqueeText(
                      text: viewModel.currentSong?.title ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                      velocity: 30, // smooth readable speed
                      gap: 60,      // larger gap between loops
                    )),
                const SizedBox(height: 8),
                Obx(() => Text(
                  viewModel.currentSong?.artist ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )),
              ],
            ),

            // Progress Bar
            Column(
              children: [
        Obx(() => ProgressBar(
                      progress: Duration(seconds: viewModel.currentPosition.value.toInt()),
                      total: Duration(seconds: viewModel.duration.value.toInt()),
                      onSeek: (duration) => viewModel.seekTo(duration),
                      barHeight: 4,
                      baseBarColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.18),
                      progressBarColor: Theme.of(context).colorScheme.primary,
                      thumbColor: Theme.of(context).colorScheme.primary,
                      thumbRadius: 6,
                      timeLabelLocation: TimeLabelLocation.none,
                    )),
                const SizedBox(height: 6),
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          viewModel.formatDuration(viewModel.currentPosition.value),
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                        Text(
                          viewModel.formatDuration(viewModel.duration.value),
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    )),
              ],
            ),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Shuffle
                Obx(() => _RoundToggle(
                      active: viewModel.isShuffleOn.value,
                      icon: viewModel.isShuffleOn.value
                          ? Icons.shuffle_on_outlined
                          : Icons.shuffle,
                      onTap: viewModel.toggleShuffle,
                    )),
                // Previous
                _RoundIcon(
                  icon: Icons.skip_previous,
                  onTap: viewModel.previousSong,
                ),
                // Play/Pause large
                Obx(() => _PrimaryRoundButton(
                      icon: viewModel.isPlaying.value ? Icons.pause : Icons.play_arrow,
                      onTap: viewModel.togglePlay,
                    )),
                // Next
                _RoundIcon(
                  icon: Icons.skip_next,
                  onTap: viewModel.nextSong,
                ),
                // Repeat
                Obx(() => _RoundToggle(
                      active: viewModel.isRepeatOn.value,
                      icon: viewModel.isRepeatOn.value ? Icons.repeat_one : Icons.repeat,
                      onTap: viewModel.toggleRepeat,
                    )),
              ],
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkColorBackground extends StatelessWidget {
  const _ArtworkColorBackground();

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();
    return Obx(() {
      final song = viewModel.currentSong;
      if (song == null) {
        return _fallbackGradient(context);
      }
      Future<File?> futureFile;
      final id = int.tryParse(song.id);
      if (id != null) {
        futureFile = ArtworkCacheService.getCachedFile(id);
      } else if (song.uri.isNotEmpty) {
        futureFile = ArtworkCacheService.getCachedFileForPath(song.uri);
      } else {
        return _fallbackGradient(context);
      }
      return FutureBuilder<File?>(
        future: futureFile,
        builder: (context, snapshot) {
          final file = snapshot.data;
          return FutureBuilder<PaletteGenerator>(
            future: _generatePalette(file),
            builder: (context, snap) {
              final palette = snap.data;
              final colors = _buildColorsFromPalette(context, palette);
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Future<PaletteGenerator> _generatePalette(File? file) async {
    try {
      if (file != null) {
        return await PaletteGenerator.fromImageProvider(Image.file(file).image,
            maximumColorCount: 12);
      }
    } catch (_) {}
    // Fallback empty palette
    return Future.value(PaletteGenerator.fromColors([]));
  }

  List<Color> _buildColorsFromPalette(BuildContext context, PaletteGenerator? p) {
    final scheme = Theme.of(context).colorScheme;
    final dominant = p?.dominantColor?.color ?? scheme.primary.withOpacity(0.4);
    final vibrant = p?.vibrantColor?.color ?? scheme.secondary.withOpacity(0.35);
    final muted = p?.mutedColor?.color ?? Colors.black.withOpacity(0.5);
    return [
      dominant.withOpacity(0.45),
      vibrant.withOpacity(0.4),
      muted.withOpacity(0.6),
    ];
  }

  Widget _fallbackGradient(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.primary.withOpacity(0.25),
            c.secondary.withOpacity(0.25),
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      splashColor: scheme.primary.withOpacity(0.2),
      highlightColor: scheme.primary.withOpacity(0.1),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surface.withOpacity(0.3),
          border: Border.all(color: scheme.outline.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, color: scheme.onSurface.withOpacity(0.95), size: 22),
      ),
    );
  }
}

class _RoundToggle extends StatelessWidget {
  final bool active;
  final IconData icon;
  final VoidCallback onTap;
  const _RoundToggle({required this.active, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 26,
      splashColor: scheme.primary.withOpacity(0.2),
      highlightColor: scheme.primary.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? scheme.primary.withOpacity(0.25)
              : scheme.surface.withOpacity(0.3),
          border: Border.all(
            color: active
                ? scheme.primary.withOpacity(0.6)
                : scheme.outline.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: active ? scheme.onPrimary : scheme.onSurface.withOpacity(0.95),
          size: 20,
        ),
      ),
    );
  }
}

class _PrimaryRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryRoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 38,
      splashColor: scheme.primary.withOpacity(0.2),
      highlightColor: scheme.primary.withOpacity(0.1),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary,
          border: Border.all(color: scheme.primary.withOpacity(0.6), width: 1),
        ),
        child: Icon(icon, color: scheme.onPrimary, size: 34),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // pixels per second
  final double gap; // gap between repeats

  const _MarqueeText({
    required this.text,
    this.style,
    this.velocity = 50,
    this.gap = 30,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10), // will be updated when sizes known
  );

  double _textWidth = 0;
  double _maxWidth = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    if (_textWidth <= 0 || _maxWidth <= 0) return;
    if (_textWidth <= _maxWidth) {
      // No animation needed
      _controller.stop();
      return;
    }
    final distance = _textWidth + widget.gap;
    final seconds = (distance / widget.velocity).clamp(5, 60); // reasonable bounds
    _controller.duration = Duration(milliseconds: (seconds * 1000).toInt());
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.style != widget.style ||
        oldWidget.gap != widget.gap ||
        oldWidget.velocity != widget.velocity) {
      // Will recompute in next build
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      // Measure text width
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
    final tWidth = painter.size.width;
    final metrics = painter.computeLineMetrics();
    final lineHeight = metrics.isNotEmpty
      ? (metrics.first.ascent + metrics.first.descent)
      : painter.height;

      // Update stateful sizes and animation if changed
      if (_textWidth != tWidth || _maxWidth != maxW) {
        _textWidth = tWidth;
        _maxWidth = maxW;
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateAnimation());
      }

      if (tWidth <= maxW) {
        return SizedBox(
          width: maxW,
          height: lineHeight + 6,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Scrolling marquee with duplicated text (Stack avoids Row overflow)
    final distance = tWidth + widget.gap; // ensures the entire text plus gap scrolls fully
      final textWidget = Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      );
    return ClipRect(
        child: SizedBox(
      width: maxW,
  height: lineHeight + 6,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = (_controller.value * distance);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: tWidth, child: textWidget),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(-offset + distance, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: tWidth, child: textWidget),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}