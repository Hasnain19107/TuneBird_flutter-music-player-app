import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song_model.dart';
import '../services/song_data_service.dart';
import '../services/music_service.dart';
import '../services/artwork_cache_service.dart';
import '../utils/time_utils.dart';
import '../utils/format_utils.dart';
import '../utils/permission_utils.dart';

class SongsController extends GetxController {
  // Reactive variables
  final RxList<Song> songs = <Song>[].obs;
  final RxBool isScanning = false.obs;
  final RxString scanStatus = ''.obs;
  final RxBool isInitialized = false.obs;
  final RxString lastScanTime = ''.obs;
  final RxBool isShuffled = false.obs;
  final RxString sortBy = 'title'.obs; // title, artist, album, date

  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  void onInit() {
    super.onInit();
    // Set initialized immediately to prevent loading screen
    isInitialized.value = true;
    // Initialize songs when controller is created (app startup)
    _initializeSongs();
  }

  Future<void> _initializeSongs() async {
    try {
      // Initialize the song data service
      await SongDataService.init();
      
      // Check cache info
      final cacheInfo = await SongDataService.getCacheInfo();

      if (cacheInfo['hasCache'] == true && cacheInfo['isValid'] == true) {
        // Load from cache immediately
        final cachedSongs = await SongDataService.loadSongs();
        songs.value = cachedSongs;
        // Keep MusicService in sync with the same list so player works instantly
        try {
          final musicService = Get.find<MusicService>();
          musicService.setLibrarySongs(cachedSongs);
        } catch (_) {}
        _updateLastScanTime(cacheInfo['lastScan']);
        // Warm-up artwork cache for first visible items
        ArtworkCacheService.warmUp(
          cachedSongs.map((s) => int.tryParse(s.id)).whereType<int>(),
        );
      }
    } catch (e) {
      // Error occurred, but controller is already initialized
    }
  }

  Future<void> scanForSongs({bool forceRefresh = false}) async {
    if (isScanning.value) return; // Prevent multiple scans

    isScanning.value = true;
    scanStatus.value = 'Checking permissions...';

    try {
      // Clear cache if force refresh
      if (forceRefresh) {
        await SongDataService.clearCache();
      }

      // Request appropriate permissions
      bool hasPermission = await _requestPermissions();
      
      if (!hasPermission) {
        _showPermissionDialog();
        isScanning.value = false;
        scanStatus.value = '';
        return;
      }

      scanStatus.value = 'Scanning for songs...';

      // Query all audio files using on_audio_query
      List<SongModel> audioFiles = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      scanStatus.value = 'Processing songs...';

      // Convert to our Song model
      List<Song> songList = [];
      for (int i = 0; i < audioFiles.length; i++) {
        final audioFile = audioFiles[i];
        
        // Update status every 50 songs
        if (i % 50 == 0) {
          scanStatus.value = 'Processing songs... (${i + 1}/${audioFiles.length})';
        }

        // Skip very short files (likely tones / notifications)
        if (audioFile.duration != null && audioFile.duration! < 30000) {
          continue;
        }

        // Skip system / recording / messaging app audio
        if (_isSystemOrRecordingAudio(audioFile)) {
          continue;
        }

        songList.add(Song(
          id: audioFile.id.toString(),
          title: audioFile.title,
          artist: audioFile.artist ?? 'Unknown Artist',
          album: audioFile.album ?? 'Unknown Album',
          duration: _formatDuration(audioFile.duration ?? 0),
          uri: audioFile.uri ?? '',
          artworkPath: null, // Will be loaded on demand
        ));
      }

  // Filter out system / generic tones (no artist and no album)
  songList = songList.where((s) => !(s.artist == 'Unknown Artist' && s.album == 'Unknown Album')).toList();

      // Update reactive variables
      songs.value = songList;
      // Also update MusicService songs so playback list matches
      try {
        final musicService = Get.find<MusicService>();
        musicService.setLibrarySongs(songList);
      } catch (_) {}
      isScanning.value = false;
      scanStatus.value = '';

      // Save to cache
  await SongDataService.saveSongs(songList);
      _updateLastScanTime(DateTime.now());

      // Warm-up artwork cache for first visible items after scan
      ArtworkCacheService.warmUp(
        songList.map((s) => int.tryParse(s.id)).whereType<int>(),
      );

    } catch (e) {
      isScanning.value = false;
      scanStatus.value = '';
    }
  }

  Future<bool> _requestPermissions() => PermissionUtils.requestAudioPermissions();

  bool _isSystemOrRecordingAudio(SongModel audioFile) {
    final uri = (audioFile.uri ?? '').toLowerCase();
    final title = (audioFile.title).toLowerCase();
  final display = (audioFile.displayName).toLowerCase();

    // Common directory/path indicators for non-music audio
    const pathPatterns = [
      '/ringtones',
      '/notifications',
      '/alarms',
      '/ui/',
      '/whatsapp audio',
      '/whatsapp voice notes',
      '/whatsapp/mediA/whatsapp voice notes',
      '/call recordings',
      '/recordings',
      '/voice recorder',
      '/voice_notes',
      '/voicenotes',
      '/screenrecorder',
      '/screen recordings',
      '/camera/audio',
    ];

    for (final p in pathPatterns) {
      if (uri.contains(p)) return true;
    }

    // Title/display patterns typical for voice notes or recordings
    final patternIndicators = [
      'aud-', // some apps prefix
      'ptt-', // push-to-talk (WhatsApp)
      'wa', // WA media hashed names
      'voice',
      'record',
      'call recording',
      'screenrecorder',
      'screen_record',
    ];

    int indicatorHits = 0;
    for (final kw in patternIndicators) {
      if (title.contains(kw) || display.contains(kw)) indicatorHits++;
      if (indicatorHits >= 2) return true; // heuristically classify
    }

    return false;
  }

  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('This app needs audio permission to scan for music files. Please grant permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) => FormatUtils.formatMmSs(milliseconds * 1.0);

  void _updateLastScanTime(DateTime? scanTime) => lastScanTime.value = TimeUtils.timeAgo(scanTime);

  // Sorting methods
  void sortSongs(String sortType) {
    sortBy.value = sortType;
    List<Song> sortedSongs = List.from(songs);
    
    switch (sortType) {
      case 'title':
        sortedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'artist':
        sortedSongs.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 'album':
        sortedSongs.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
        break;
      case 'duration':
        sortedSongs.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    
    songs.value = sortedSongs;
  }

  // Shuffle songs
  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
    if (isShuffled.value) {
      List<Song> shuffledSongs = List.from(songs);
      shuffledSongs.shuffle();
      songs.value = shuffledSongs;
    } else {
      // Re-apply current sort
      sortSongs(sortBy.value);
    }
  }

  // Search songs
  List<Song> searchSongs(String query) {
    if (query.isEmpty) return songs;
    
    return songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
             song.artist.toLowerCase().contains(query.toLowerCase()) ||
             song.album.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Public method to force refresh
  Future<void> refreshSongs() async {
    await scanForSongs(forceRefresh: true);
  }

  // Get cache info for UI
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await SongDataService.getCacheInfo();
  }
}
