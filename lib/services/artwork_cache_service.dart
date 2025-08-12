import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:metadata_god/metadata_god.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';


class ArtworkCacheService {
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static Directory? _cacheDir;

  static Future<void> _ensureDir() async {
    if (_cacheDir != null) return;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/artwork_cache');
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
  }

  static Future<File?> getCachedFile(int songId) async {
    await _ensureDir();
    final file = File('${_cacheDir!.path}/$songId.jpg');
    return await file.exists() ? file : null;
  }

  static String _keyFromPath(String path) => base64Url.encode(utf8.encode(path));

  static Future<File?> getCachedFileForPath(String path) async {
    await _ensureDir();
    final key = _keyFromPath(path);
    final file = File('${_cacheDir!.path}/$key.jpg');
    return await file.exists() ? file : null;
  }

  static Future<File?> ensureCached(int songId, {int size = 200, int quality = 50}) async {
    await _ensureDir();
    final existing = await getCachedFile(songId);
    if (existing != null) return existing;
    try {
      final Uint8List? bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        size: size,
        quality: quality,
      );
      if (bytes == null || bytes.isEmpty) return null;
      final file = File('${_cacheDir!.path}/$songId.jpg');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> ensureCachedForPath(String path) async {
    await _ensureDir();
    final existing = await getCachedFileForPath(path);
    if (existing != null) return existing;
    try {
      final meta = await MetadataGod.readMetadata(file: path);
      final Uint8List? bytes = meta.picture?.data;
      if (bytes == null || bytes.isEmpty) return null;
      final key = _keyFromPath(path);
      final file = File('${_cacheDir!.path}/$key.jpg');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<void> warmUp(Iterable<int> songIds, {int count = 40}) async {
    int started = 0;
    for (final id in songIds) {
      if (started >= count) break;
      started++;
      // Fire and forget individual caches to avoid blocking UI
      // ignore: unawaited_futures
      ensureCached(id);
    }
  }
}
