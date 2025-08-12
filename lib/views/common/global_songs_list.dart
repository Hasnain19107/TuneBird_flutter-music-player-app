import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/song_model.dart';
import '../../services/music_service.dart';
import '../../services/artwork_cache_service.dart';
import '../../utils/format_utils.dart';


enum SongSource { library, custom }

class GlobalSongsList extends StatelessWidget {
  final SongSource source;
  final List<Song>? customSongs; // required when source == custom
  final bool isTemporaryQueue; // if true, playing a song uses a temporary queue (e.g., folder)
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final void Function(Song song, int index)? onSongTap;
  final String? query; // optional search query applied client-side

  const GlobalSongsList({
    super.key,
    required this.source,
    this.customSongs,
    this.isTemporaryQueue = false,
    this.padding = const EdgeInsets.only(bottom: 8),
    this.controller,
    this.onSongTap,
    this.query,
  });

  @override
  Widget build(BuildContext context) {
    final musicService = Get.find<MusicService>();
    if (source == SongSource.library) {
      // Reactive build for library songs; show playback queue order when not using a temporary queue
      return Obx(() {
        final list = !musicService.isUsingTemporaryQueue
            ? List<Song>.from(musicService.songs)
            : List<Song>.from(musicService.librarySongs);
        return _buildList(list, musicService);
      });
    }
    // Non-reactive build for custom songs (avoid GetX warning)
    return _buildList(customSongs ?? const <Song>[], musicService);
  }

  Widget _buildList(List<Song> songs, MusicService musicService) {
    // Apply query filter if provided
    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      songs = songs.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.artist.toLowerCase().contains(q) ||
        s.album.toLowerCase().contains(q)
      ).toList();
    }
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.music_note, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No songs')
          ],
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          key: ValueKey(song.id + song.uri),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[800],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _CombinedArtworkThumb(
                key: ValueKey('${song.id}_${song.uri}'),
                songId: song.id,
                path: song.uri,
              ),
            ),
          ),
          title: Text(
            song.title,
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '320K',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(song.duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
          onTap: () async {
            if (onSongTap != null) {
              onSongTap!(song, index);
              return;
            }
            if (source == SongSource.library) {
              if (musicService.isUsingTemporaryQueue) {
                await musicService.restoreLibraryQueue(startIndex: index);
              } else {
                await musicService.playSong(index);
              }
            } else {
              if (isTemporaryQueue) {
                await musicService.setTemporaryQueue(songs, startIndex: index);
              } else {
                await musicService.playSong(index);
              }
            }
          },
        );
      },
    );
  }

  String _formatDuration(String? duration) => FormatUtils.formatMmSs(duration);
}


class _CombinedArtworkThumb extends StatefulWidget {
  final String songId;
  final String path;
  const _CombinedArtworkThumb({super.key, required this.songId, required this.path});

  @override
  State<_CombinedArtworkThumb> createState() => _CombinedArtworkThumbState();
}

class _CombinedArtworkThumbState extends State<_CombinedArtworkThumb> {
  ImageProvider? _image;
  bool _loading = false;
  int? _resolvedId; // media store ID resolved from title/path if possible

  static const int _maxIdEntries = 200;
  static final Map<int, ImageProvider> _idCache = <int, ImageProvider>{};
  static final List<int> _idOrder = <int>[];
  static const int _maxPathEntries = 150;
  static final Map<String, ImageProvider> _pathCache = <String, ImageProvider>{};
  static final List<String> _pathOrder = <String>[];

  void _cacheId(int id, ImageProvider img) {
    _idCache[id] = img; _idOrder.remove(id); _idOrder.add(id);
    if (_idOrder.length > _maxIdEntries) { final ev = _idOrder.removeAt(0); _idCache.remove(ev); }
  }
  void _cachePath(String p, ImageProvider img) {
    _pathCache[p] = img; _pathOrder.remove(p); _pathOrder.add(p);
    if (_pathOrder.length > _maxPathEntries) { final ev = _pathOrder.removeAt(0); _pathCache.remove(ev); }
  }

  @override
  void initState() { super.initState(); _tryResolveIdAndLoad(); }
  @override
  void didUpdateWidget(covariant _CombinedArtworkThumb oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.songId != widget.songId || oldWidget.path != widget.path) { _image = null; _resolvedId = null; _tryResolveIdAndLoad(); } }

  Future<void> _tryResolveIdAndLoad() async {
    final parsedId = int.tryParse(widget.songId);
    if (parsedId != null) {
      _resolvedId = parsedId;
      _tryLoad();
      return;
    }
    try {
      final musicService = Get.isRegistered<MusicService>() ? Get.find<MusicService>() : null;
      if (musicService != null) {
        final baseName = widget.path.split(Platform.pathSeparator).last.split('.').first.toLowerCase();
        for (final s in musicService.librarySongs) {
          final id = int.tryParse(s.id);
          if (id == null) continue;
            final titleNorm = s.title.toLowerCase();
            if (titleNorm == baseName || baseName.replaceAll('_', ' ') == titleNorm.replaceAll('_', ' ')) {
              _resolvedId = id; break;
            }
        }
      }
    } catch (_) {}
    _tryLoad();
  }

  Future<void> _tryLoad() async {
    if (_loading) return; _loading = true;
    final parsedId = _resolvedId;
    if (parsedId != null) {
      final cached = _idCache[parsedId];
      if (cached != null) { if (mounted) setState(() { _image = cached; }); _loading = false; return; }
      final file = await ArtworkCacheService.getCachedFile(parsedId);
      if (file != null && mounted) { setState(() { _image = FileImage(file); }); _cacheId(parsedId, _image!); _loading = false; return; }
      ArtworkCacheService.ensureCached(parsedId).then((f) { if (f != null && mounted && _image == null) { setState(() { _image = FileImage(f); }); _cacheId(parsedId, _image!); } });
    }
    final path = widget.path;
    final pcached = _pathCache[path];
    if (pcached != null) { setState(() { _image = pcached; }); _loading = false; return; }
    final pfile = await ArtworkCacheService.getCachedFileForPath(path);
    if (pfile != null && mounted) { setState(() { _image = FileImage(pfile); }); _cachePath(path, _image!); _loading = false; return; }
    ArtworkCacheService.ensureCachedForPath(path).then((f) { if (f != null && mounted && _image == null) { setState(() { _image = FileImage(f); }); _cachePath(path, _image!); } });
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return Image(image: _image!, fit: BoxFit.cover, gaplessPlayback: true);
    }
    return const Icon(Icons.music_note, color: Colors.grey);
  }
}
