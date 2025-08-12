import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/directory_info_model.dart';
import '../services/folder_data_service.dart';
import '../utils/time_utils.dart';
import '../utils/permission_utils.dart';
import '../models/song_model.dart';
import '../services/music_service.dart';
import '../viewmodels/music_viewmodel.dart';
import 'dart:io';
import '../services/artwork_cache_service.dart';

class FolderController extends GetxController {
  // Reactive variables
  final RxList<DirectoryInfo> audioDirectories = <DirectoryInfo>[].obs;
  final RxBool isScanning = false.obs;
  final RxString scanStatus = ''.obs;
  final RxBool isInitialized = false.obs;
  final RxString lastScanTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Set initialized immediately to prevent loading screen
    isInitialized.value = true;
    // Initialize folders when controller is created (app startup)
    _initializeFolders();
  }

  Future<void> _initializeFolders() async {
    try {
      // Initialize the folder data service
      await FolderDataService.init();
      
      // Check cache info
      final cacheInfo = await FolderDataService.getCacheInfo();

      if (cacheInfo['hasCache'] == true && cacheInfo['isValid'] == true) {
        // Load from cache immediately
        final cachedDirectories = await FolderDataService.loadDirectories();
        audioDirectories.value = cachedDirectories;
        _updateLastScanTime(cacheInfo['lastScan']);
      }
    } catch (e) {
      // Error occurred, but controller is already initialized
    }
  }

  Future<void> scanForAudioDirectories({bool forceRefresh = false}) async {
    if (isScanning.value) return; // Prevent multiple scans

    isScanning.value = true;
    scanStatus.value = 'Checking permissions...';

    try {
      // Clear cache if force refresh
      if (forceRefresh) {
        await FolderDataService.clearCache();
      }

      // Request appropriate permissions based on Android version
      bool hasPermission = await _requestPermissions();
      
      if (!hasPermission) {
        _showPermissionDialog();
        isScanning.value = false;
        scanStatus.value = '';
        return;
      }

      scanStatus.value = 'Getting directories...';

      List<DirectoryInfo> directories = [];

      // Get various storage directories to scan
      List<Directory> dirsToScan = await _getDirectoriesToScan();
      
      for (int i = 0; i < dirsToScan.length; i++) {
        Directory dir = dirsToScan[i];
        scanStatus.value = 'Scanning ${dir.path.split(Platform.pathSeparator).last}... (${i + 1}/${dirsToScan.length})';
        
        if (await dir.exists()) {
          await _scanDirectory(dir, directories);
        }
      }

      // Update reactive variables
      audioDirectories.value = directories;
      isScanning.value = false;
      scanStatus.value = '';

      // Save to cache
      await FolderDataService.saveDirectories(directories);
      _updateLastScanTime(DateTime.now());

    } catch (e) {
      isScanning.value = false;
      scanStatus.value = '';
    }
  }

  Future<void> _scanDirectory(Directory dir, List<DirectoryInfo> result) async {
    try {
      await _scanDirectoryRecursively(dir, result, 0, 5); // Max depth of 5 levels
    } catch (e) {
      // Handle error silently and continue
    }
  }

  Future<void> _scanDirectoryRecursively(Directory dir, List<DirectoryInfo> result, int currentDepth, int maxDepth) async {
    if (currentDepth > maxDepth) return;
    final lowerPath = dir.path.toLowerCase();
    // Skip common system tone / notification directories entirely
    if (lowerPath.contains('ringtones') || lowerPath.contains('notifications') || lowerPath.contains('alarms') || lowerPath.contains('/ui/')) {
      return;
    }
    
    try {
      List<File> audioFiles = [];
      List<Directory> subDirectories = [];

      await for (var entity in dir.list(followLinks: false)) {
        try {
          if (entity is File) {
            String ext = entity.path.split('.').last.toLowerCase();
            if (_isAudioFile(ext)) {
              audioFiles.add(entity);
            }
          } else if (entity is Directory) {
            // Skip hidden directories and Android system directories
            String dirName = entity.path.split(Platform.pathSeparator).last;
            if (!dirName.startsWith('.') && 
                !dirName.startsWith('Android') && 
                !dirName.contains('cache') &&
                !dirName.contains('temp')) {
              final lp = entity.path.toLowerCase();
              if (lp.contains('ringtones') || lp.contains('notifications') || lp.contains('alarms')) {
                continue; // skip system tone subdirectories
              }
              subDirectories.add(entity);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // If current directory has audio files, add it to results
      if (audioFiles.isNotEmpty) {
        String dirName = dir.path.split(Platform.pathSeparator).last;
        if (dirName.isEmpty) dirName = 'Root';
        
        result.add(DirectoryInfo(
          path: dir.path,
          name: dirName,
          audioFileCount: audioFiles.length,
          audioFiles: audioFiles,
        ));
      }

      // Recursively scan subdirectories
      for (Directory subDir in subDirectories) {
        await _scanDirectoryRecursively(subDir, result, currentDepth + 1, maxDepth);
      }

    } catch (e) {
      // Handle error silently and continue
    }
  }

  Future<bool> _requestPermissions() => PermissionUtils.requestAudioPermissions();

  Future<List<Directory>> _getDirectoriesToScan() async {
    List<Directory> directories = [];
    
    try {
      // Get external storage directory
      Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        // Try to get the root storage path
        String rootPath = externalDir.path.split('/Android/')[0];

        // Common music directories - expanded list
        List<String> commonPaths = [
          '$rootPath/Music',
          '$rootPath/Download',
          '$rootPath/Downloads',
          '$rootPath/AudioBooks',
          '$rootPath/Ringtones',
          '$rootPath/Notifications',
          '$rootPath/Podcasts',
          '$rootPath/Audio',
          '$rootPath/Sounds',
          '$rootPath/media/audio',
          
        ];

        for (String path in commonPaths) {
          Directory dir = Directory(path);
          if (await dir.exists()) {
            directories.add(dir);
          }
        }
        
        // Also try scanning the root storage directory itself (but limit depth)
        Directory rootDir = Directory(rootPath);
        if (await rootDir.exists()) {
          directories.add(rootDir);
        }
      }
      
      // Add application documents directory
      Directory appDir = await getApplicationDocumentsDirectory();
      directories.add(appDir);
      
    } catch (e) {
      // Handle error silently
    }
    
    return directories;
  }

  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('This app needs storage permission to scan for audio files. Please grant permission in app settings.'),
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

  bool _isAudioFile(String ext) {
    const audioExts = ['mp3', 'm4a', 'aac', 'ogg', 'wav', 'flac', 'opus', 'wma', '3gp', 'amr'];
    return audioExts.contains(ext);
  }

  void _updateLastScanTime(DateTime? scanTime) => lastScanTime.value = TimeUtils.timeAgo(scanTime);

  // Public method to force refresh
  Future<void> refreshFolders() async {
    await scanForAudioDirectories(forceRefresh: true);
  }

  // Get cache info for UI
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await FolderDataService.getCacheInfo();
  }

  // ===================== New abstraction layer for folder -> songs =====================
  /// Build Song objects for a directory. Attempts to map file-based songs to existing
  /// library songs (for artwork / metadata) when possible; otherwise creates lightweight entries.
  List<Song> buildSongsForDirectory(DirectoryInfo dirInfo) {
    final musicService = Get.isRegistered<MusicService>() ? Get.find<MusicService>() : null;
    final librarySongs = musicService?.librarySongs ?? const <Song>[];
    // Build fast exact map
    final Map<String, Song> nameMap = {
      for (final s in librarySongs) _normalizeName(s.title): s
    };

    final List<Song> songs = [];
    final List<File> files = dirInfo.audioFiles;
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final rawBase = _fileNameWithoutExtension(_fileName(file.path));
      final baseName = _normalizeName(rawBase);
      Song? mapped = nameMap[baseName];

      // If no direct match, attempt fuzzy token match
      if (mapped == null && librarySongs.isNotEmpty) {
        mapped = _fuzzyMatch(baseName, librarySongs);
      }

      songs.add(mapped ?? _createSongFromFile(dirInfo, file, i));
    }

  // Filter out songs with no artist & no album metadata (likely system tones)
  final filtered = songs.where((s) => !(s.artist == 'Unknown Artist' && s.album == 'Unknown Album')).toList();

    // Warm up artwork (limit to first 60 to avoid heavy I/O)
    try {
      final first = songs.take(60).toList();
      final ids = first
          .map((s) => int.tryParse(s.id))
          .whereType<int>();
      if (ids.isNotEmpty) {
        // ignore: unawaited_futures
        ArtworkCacheService.warmUp(ids);
      }
      for (final s in first) {
        if (int.tryParse(s.id) == null && s.uri.isNotEmpty) {
          // ignore: unawaited_futures
          ArtworkCacheService.ensureCachedForPath(s.uri);
        }
      }
    } catch (_) {}

  return filtered;
  }

  /// Play all songs in a directory as a temporary queue.
  Future<void> playDirectory(DirectoryInfo dirInfo, {int startIndex = 0}) async {
    final songs = buildSongsForDirectory(dirInfo);
    await _setTemporaryQueueAndPlay(songs, startIndex);
  }

  /// Play a single song (by index) within the directory context.
  Future<void> playSongInDirectory(DirectoryInfo dirInfo, int index) async {
    final songs = buildSongsForDirectory(dirInfo);
    if (index < 0 || index >= songs.length) return;
    await _setTemporaryQueueAndPlay(songs, index);
  }

  // -------------------- Internal helpers --------------------
  Future<void> _setTemporaryQueueAndPlay(List<Song> songs, int index) async {
    try {
      final musicService = Get.find<MusicService>();
      await musicService.setTemporaryQueue(songs, startIndex: index);
    } catch (_) {
      // Fallback to viewmodel if music service not available
      final vm = Get.isRegistered<MusicViewModel>() ? Get.find<MusicViewModel>() : null;
      if (vm != null) {
        vm.songs
          ..clear()
          ..addAll(songs);
        vm.playSong(index);
      }
    }
  }

  Song _createSongFromFile(DirectoryInfo dirInfo, File file, int index) {
    final title = _fileNameWithoutExtension(_fileName(file.path));
    return Song(
      id: 'folder_${dirInfo.name}_$index',
      title: title,
      artist: 'Unknown Artist',
  album: 'Unknown Album',
      duration: '0',
      uri: file.path,
      artworkPath: null,
    );
  }

  String _fileName(String path) => path.split(Platform.pathSeparator).last;
  String _fileNameWithoutExtension(String fileName) {
    final i = fileName.lastIndexOf('.');
    return i == -1 ? fileName : fileName.substring(0, i);
  }
  String _normalizeName(String input) {
    var n = input.toLowerCase();
    // Remove leading track numbers (e.g., 01-, 1., 07 )
    n = n.replaceFirst(RegExp(r'^[0-9]{1,3}[\s._-]+'), '');
    // Remove bracketed prefixes [live] (remastered) etc at start
    n = n.replaceFirst(RegExp(r'^[\[(][^\])]+[\])]\s*'), '');
    // Common tags
    for (final tag in ['official video', 'official audio', 'lyrics', 'lyric video']) {
      n = n.replaceAll(tag, '');
    }
    n = n.replaceAll('_', ' ').replaceAll('-', ' ');
    n = n.replaceAll(RegExp(r'\s+'), ' ').trim();
    return n;
  }

  Song? _fuzzyMatch(String base, List<Song> librarySongs) {
    List<String> baseTokens = base.split(' ');
    Song? best;
    double bestScore = 0;
    for (final s in librarySongs) {
      final norm = _normalizeName(s.title);
      if (norm == base || norm.contains(base) || base.contains(norm)) {
        // Prefer exact/contain match immediately
        return s;
      }
      final tokens = norm.split(' ');
      final intersect = tokens.toSet().intersection(baseTokens.toSet());
      final double ratio = intersect.isEmpty ? 0.0 : intersect.length / (baseTokens.length + 0.5);
      if (ratio > 0.6 && ratio > bestScore) {
        bestScore = ratio;
        best = s;
      }
    }
    return bestScore >= 0.6 ? best : null;
  }
}
