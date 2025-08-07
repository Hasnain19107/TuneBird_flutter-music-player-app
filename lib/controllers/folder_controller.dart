import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/directory_info_model.dart';
import '../services/folder_data_service.dart';
import 'dart:io';

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
    // Initialize folders when controller is created (app startup)
    _initializeFolders();
  }

  Future<void> _initializeFolders() async {
    try {
      // Initialize the folder data service
      await FolderDataService.init();
      
      // Check cache info
      final cacheInfo = await FolderDataService.getCacheInfo();
      print('Cache info: $cacheInfo');

      if (cacheInfo['hasCache'] == true && cacheInfo['isValid'] == true) {
        // Load from cache immediately
        final cachedDirectories = await FolderDataService.loadDirectories();
        audioDirectories.value = cachedDirectories;
        _updateLastScanTime(cacheInfo['lastScan']);
        isInitialized.value = true;
        print('Loaded ${cachedDirectories.length} directories from cache');
      } else {
        // Need to scan fresh
        print('No valid cache found, will scan...');
        isInitialized.value = true;
        await scanForAudioDirectories();
      }
    } catch (e) {
      print('Error initializing folder data: $e');
      isInitialized.value = true;
      // Fallback to fresh scan
      await scanForAudioDirectories();
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
        print("Permissions not granted");
        _showPermissionDialog();
        isScanning.value = false;
        scanStatus.value = '';
        return;
      }

      scanStatus.value = 'Getting directories...';

      List<DirectoryInfo> directories = [];

      // Get various storage directories to scan
      List<Directory> dirsToScan = await _getDirectoriesToScan();
      
      print("Found ${dirsToScan.length} directories to scan");
      
      for (int i = 0; i < dirsToScan.length; i++) {
        Directory dir = dirsToScan[i];
        scanStatus.value = 'Scanning ${dir.path.split(Platform.pathSeparator).last}... (${i + 1}/${dirsToScan.length})';
        
        if (await dir.exists()) {
          print("Scanning directory: ${dir.path}");
          await _scanDirectory(dir, directories);
        } else {
          print("Directory not found: ${dir.path}");
        }
      }

      print("Found ${directories.length} directories with audio files");

      // Update reactive variables
      audioDirectories.value = directories;
      isScanning.value = false;
      scanStatus.value = '';

      // Save to cache
      await FolderDataService.saveDirectories(directories);
      _updateLastScanTime(DateTime.now());
      print('Saved ${directories.length} directories to cache');

    } catch (e) {
      print('Error scanning: $e');
      isScanning.value = false;
      scanStatus.value = '';
    }
  }

  Future<void> _scanDirectory(Directory dir, List<DirectoryInfo> result) async {
    try {
      await _scanDirectoryRecursively(dir, result, 0, 5); // Max depth of 5 levels
    } catch (e) {
      print('Error scanning directory ${dir.path}: $e');
    }
  }

  Future<void> _scanDirectoryRecursively(Directory dir, List<DirectoryInfo> result, int currentDepth, int maxDepth) async {
    if (currentDepth > maxDepth) return;
    
    try {
      List<File> audioFiles = [];
      List<Directory> subDirectories = [];

      await for (var entity in dir.list(followLinks: false)) {
        try {
          if (entity is File) {
            String ext = entity.path.split('.').last.toLowerCase();
            if (_isAudioFile(ext)) {
              print("Found audio file: ${entity.path}");
              audioFiles.add(entity);
            }
          } else if (entity is Directory) {
            // Skip hidden directories and Android system directories
            String dirName = entity.path.split(Platform.pathSeparator).last;
            if (!dirName.startsWith('.') && 
                !dirName.startsWith('Android') && 
                !dirName.contains('cache') &&
                !dirName.contains('temp')) {
              subDirectories.add(entity);
            }
          }
        } catch (e) {
          print('Error processing entity ${entity.path}: $e');
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
      print('Error reading directory ${dir.path}: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      // For Android 13+ (API 33+), use READ_MEDIA_AUDIO
      if (Platform.isAndroid) {
        var status = await Permission.audio.status;
        if (status.isDenied) {
          status = await Permission.audio.request();
        }
        
        if (status.isGranted) {
          return true;
        }
        
        // Fallback to storage permission for older devices
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }
        
        return storageStatus.isGranted;
      }
      
      return true; // iOS and other platforms
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<List<Directory>> _getDirectoriesToScan() async {
    List<Directory> directories = [];
    
    try {
      // Get external storage directory
      Directory? externalDir = await getExternalStorageDirectory();
      print("External Dir: ${externalDir?.path}");

      if (externalDir != null) {
        // Try to get the root storage path
        String rootPath = externalDir.path.split('/Android/')[0];
        print("Root Path: $rootPath");

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
          '$rootPath/DCIM', // Sometimes audio files are here
          '$rootPath/WhatsApp/Media/WhatsApp Audio', // WhatsApp audio
          '$rootPath/Telegram/Telegram Audio', // Telegram audio
        ];

        for (String path in commonPaths) {
          Directory dir = Directory(path);
          if (await dir.exists()) {
            print("Adding directory to scan: $path");
            directories.add(dir);
          } else {
            print("Directory not found: $path");
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
      print('Error getting directories to scan: $e');
    }
    
    print("Total directories to scan: ${directories.length}");
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

  void _updateLastScanTime(DateTime? scanTime) {
    if (scanTime == null) return;
    
    final timeAgo = DateTime.now().difference(scanTime);
    String timeText = '';
    if (timeAgo.inMinutes < 1) {
      timeText = 'Just now';
    } else if (timeAgo.inMinutes < 60) {
      timeText = '${timeAgo.inMinutes}m ago';
    } else if (timeAgo.inHours < 24) {
      timeText = '${timeAgo.inHours}h ago';
    } else {
      timeText = '${timeAgo.inDays}d ago';
    }
    
    lastScanTime.value = timeText;
  }

  // Public method to force refresh
  Future<void> refreshFolders() async {
    await scanForAudioDirectories(forceRefresh: true);
  }

  // Get cache info for UI
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await FolderDataService.getCacheInfo();
  }
}
