import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_model.dart';
import '../models/song_model_hive.dart';

class SongDataService {
  static const String _boxName = 'song_data';
  static Box<SongModelHive>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SongModelHiveAdapter());
    }
    _box = await Hive.openBox<SongModelHive>(_boxName);
  }

  static Box<SongModelHive> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SongDataService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Save scanned songs
  static Future<void> saveSongs(List<Song> songs) async {
    try {
      await box.clear(); // Clear old data
      
      final models = songs.map((song) => SongModelHive.fromSong(song)).toList();
      
      for (int i = 0; i < models.length; i++) {
        await box.put('song_$i', models[i]);
      }
      
      // Save scan timestamp
      await box.put('last_scan_time', SongModelHive(
        id: '__metadata__',
        title: '__metadata__',
        artist: '__metadata__',
        album: '__metadata__',
        duration: '00:00',
        uri: '',
        artworkPath: null,
        lastScanned: DateTime.now(),
      ));
      
    } catch (e) {
      // Handle error silently
    }
  }

  // Load cached songs
  static Future<List<Song>> loadSongs() async {
    try {
      final List<Song> songs = [];
      
      for (final key in box.keys) {
        if (key.toString().startsWith('song_')) {
          final model = box.get(key);
          if (model != null) {
            songs.add(model.toSong());
          }
        }
      }
      
      return songs;
    } catch (e) {
      return [];
    }
  }

  // Check if cache is valid (not older than 7 days for songs)
  static Future<bool> isCacheValid() async {
    try {
      final metadata = box.get('last_scan_time');
      if (metadata == null) return false;
      
      final lastScan = metadata.lastScanned;
      final now = DateTime.now();
      final difference = now.difference(lastScan);
      
      // Cache is valid for 7 days (songs don't change as often as folders)
      return difference.inDays < 7;
    } catch (e) {
      return false;
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      await box.clear();
    } catch (e) {
      // Handle error silently
    }
  }

  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final metadata = box.get('last_scan_time');
      if (metadata == null) {
        return {'hasCache': false, 'lastScan': null, 'count': 0};
      }

      final count = box.keys.where((key) => key.toString().startsWith('song_')).length;
      
      return {
        'hasCache': true,
        'lastScan': metadata.lastScanned,
        'count': count,
        'isValid': await isCacheValid(),
      };
    } catch (e) {
      return {'hasCache': false, 'lastScan': null, 'count': 0};
    }
  }
}
