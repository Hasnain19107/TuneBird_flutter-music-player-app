import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../player/player_view.dart';
import '../../services/artwork_cache_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:io';

/// Reusable mini player reflecting current playback queue (library or temporary).
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<MusicViewModel>();
    return Obx(() {
      final song = vm.currentSong;
      if (song == null) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Get.to(() => const PlayerView()),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              _MiniArtwork(songId: song.id, uri: song.uri),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniMarquee(
                      text: song.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      velocity: 40,
                      gap: 40,
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              _MiniControls(vm: vm),
            ],
          ),
        ),
      );
    });
  }
}

class _MiniControls extends StatelessWidget {
  final MusicViewModel vm;
  const _MiniControls({required this.vm});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Obx(() => Icon(vm.isPlaying.value ? Icons.pause : Icons.play_arrow)),
          onPressed: vm.togglePlay,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: vm.nextSong,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _MiniArtwork extends StatefulWidget {
  final String songId;
  final String uri;
  const _MiniArtwork({required this.songId, required this.uri});
  @override
  State<_MiniArtwork> createState() => _MiniArtworkState();
}

class _MiniArtworkState extends State<_MiniArtwork> {
  ImageProvider? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _MiniArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId || oldWidget.uri != widget.uri) {
      _image = null;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return; _loading = true;
    final id = int.tryParse(widget.songId);
    File? file;
    if (id != null) {
      file = await ArtworkCacheService.getCachedFile(id);
      if (file == null) {
        ArtworkCacheService.ensureCached(id);
      }
    }
    if (file == null && widget.uri.isNotEmpty) {
      file = await ArtworkCacheService.getCachedFileForPath(widget.uri);
      if (file == null) {
        ArtworkCacheService.ensureCachedForPath(widget.uri);
      }
    }
    if (!mounted) return;
    if (file != null) {
      setState(() { _image = FileImage(file!); });
    }
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.songId);
    Widget art;
    if (_image != null) {
      art = Image(image: _image!, fit: BoxFit.cover);
    } else if (id != null) {
      art = QueryArtworkWidget(
        id: id,
        type: ArtworkType.AUDIO,
        nullArtworkWidget: const Icon(Icons.music_note, color: Colors.grey),
      );
    } else {
      art = const Icon(Icons.music_note, color: Colors.grey);
    }
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[800],
      ),
      clipBehavior: Clip.antiAlias,
      child: art,
    );
  }
}

/// Lightweight marquee used in mini player (independent from player view private widget)
class _MiniMarquee extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // px per second
  final double gap; // gap between repeats
  const _MiniMarquee({
    required this.text,
    this.style,
    this.velocity = 40,
    this.gap = 30,
  });
  @override
  State<_MiniMarquee> createState() => _MiniMarqueeState();
}

class _MiniMarqueeState extends State<_MiniMarquee> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _textWidth = 0;
  double _maxWidth = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _configure() {
    if (_textWidth <= 0 || _maxWidth <= 0) return;
    if (_textWidth <= _maxWidth) {
      _controller.stop();
      return;
    }
    final distance = _textWidth + widget.gap;
    final seconds = (distance / widget.velocity).clamp(4, 40);
    _controller.duration = Duration(milliseconds: (seconds * 1000).toInt());
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      final tWidth = painter.size.width;
      final metrics = painter.computeLineMetrics();
      final lineHeight = metrics.isNotEmpty ? (metrics.first.ascent + metrics.first.descent) : painter.height;

      if (_textWidth != tWidth || _maxWidth != maxW) {
        _textWidth = tWidth;
        _maxWidth = maxW;
        WidgetsBinding.instance.addPostFrameCallback((_) => _configure());
      }

      if (tWidth <= maxW) {
        return SizedBox(
          width: maxW,
          height: lineHeight + 4,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.clip,
              softWrap: false,
            ),
          ),
        );
      }

      final distance = tWidth + widget.gap;
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
          height: lineHeight + 4,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = (_controller.value * distance);
              return Stack(
                children: [
                  Transform.translate(
                    offset: Offset(-offset, 0),
                    child: SizedBox(width: tWidth, child: textWidget),
                  ),
                  Transform.translate(
                    offset: Offset(-offset + distance, 0),
                    child: SizedBox(width: tWidth, child: textWidget),
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
