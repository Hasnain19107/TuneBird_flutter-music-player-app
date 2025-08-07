import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/directory_info_model.dart';
import '../../services/folder_data_service.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../../models/song_model.dart';
import '../player/player_view.dart';
import 'dart:io';

class FolderView extends StatefulWidget {
  const FolderView({super.key});

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  List<DirectoryInfo> _audioDirectories = [];
  bool _isScanning = false;
  String _scanStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeFolderData();
  }

  Future<void> _initializeFolderData() async {
    try {
      // Initialize the folder data service
      await FolderDataService.init();
      
      // Check cache info
      final cacheInfo = await FolderDataService.getCacheInfo();
      print('Cache info: $cacheInfo');

      if (cacheInfo['hasCache'] == true && cacheInfo['isValid'] == true) {
        // Load from cache
        final cachedDirectories = await FolderDataService.loadDirectories();
        setState(() {
          _audioDirectories = cachedDirectories;
        });
        print('Loaded ${cachedDirectories.length} directories from cache');
      } else {
        // Scan fresh
        print('No valid cache found, scanning...');
        await _scanForAudioDirectories();
      }
    } catch (e) {
      print('Error initializing folder data: $e');
      // Fallback to fresh scan
      await _scanForAudioDirectories();
    }
  }

  Future<void> _scanForAudioDirectories() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Checking permissions...';
    });

    try {
      // Request appropriate permissions based on Android version
      bool hasPermission = await _requestPermissions();
      
      if (!hasPermission) {
        print("Permissions not granted");
        _showPermissionDialog();
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        return;
      }

      setState(() {
        _scanStatus = 'Getting directories...';
      });

      List<DirectoryInfo> directories = [];

      // Get various storage directories to scan
      List<Directory> dirsToScan = await _getDirectoriesToScan();
      
      print("Found ${dirsToScan.length} directories to scan");
      
      for (int i = 0; i < dirsToScan.length; i++) {
        Directory dir = dirsToScan[i];
        setState(() {
          _scanStatus = 'Scanning ${dir.path.split(Platform.pathSeparator).last}... (${i + 1}/${dirsToScan.length})';
        });
        
        if (await dir.exists()) {
          print("Scanning directory: ${dir.path}");
          await _scanDirectory(dir, directories);
        } else {
          print("Directory not found: ${dir.path}");
        }
      }

      print("Found ${directories.length} directories with audio files");

      setState(() {
        _audioDirectories = directories;
        _isScanning = false;
        _scanStatus = '';
      });

      // Save to cache
      await FolderDataService.saveDirectories(directories);
      print('Saved ${directories.length} directories to cache');

    } catch (e) {
      print('Error scanning: $e');
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    _isScanning ? 'Scanning...' : '${_audioDirectories.length} Folders',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isScanning ? null : () {
                      // Force refresh by clearing cache
                      FolderDataService.clearCache();
                      _scanForAudioDirectories();
                    },
                    tooltip: 'Refresh folders',
                  ),
                ],
              ),
              if (!_isScanning && _audioDirectories.isNotEmpty)
                FutureBuilder<Map<String, dynamic>>(
                  future: FolderDataService.getCacheInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!['hasCache'] == true) {
                      final lastScan = snapshot.data!['lastScan'] as DateTime?;
                      if (lastScan != null) {
                        final timeAgo = DateTime.now().difference(lastScan);
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
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Last scanned: $timeText',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isScanning
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_scanStatus.isEmpty ? 'Scanning...' : _scanStatus),
                    ],
                  ),
                )
              : _audioDirectories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No audio folders found'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // Force refresh by clearing cache
                              FolderDataService.clearCache();
                              _scanForAudioDirectories();
                            },
                            child: const Text('Scan Again'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _audioDirectories.length,
                      itemBuilder: (context, index) {
                        final dir = _audioDirectories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.folder,
                                color: Colors.orange,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              dir.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${dir.audioFileCount} audio files',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dir.path,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill),
                                  onPressed: () {
                                    // Play first song in this directory
                                    _playDirectorySongs(dir, 0);
                                  },
                                  color: Theme.of(context).primaryColor,
                                  tooltip: 'Play all',
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => _openDirectory(context, dir),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _openDirectory(BuildContext context, DirectoryInfo dirInfo) {
    Get.to(() => DirectoryDetailView(directoryInfo: dirInfo));
  }

  Future<void> _playDirectorySongs(DirectoryInfo dirInfo, int startIndex) async {
    try {
      final viewModel = Get.find<MusicViewModel>();
      
      // Create Song objects for all files in this directory
      final directorySongs = dirInfo.audioFiles
          .asMap()
          .entries
          .map((entry) => Song(
                id: 'dir_${dirInfo.name}_${entry.key}',
                title: entry.value.path.split(Platform.pathSeparator).last
                    .split('.').first, // Remove extension
                artist: 'Unknown Artist',
                album: dirInfo.name,
                duration: '0',
                uri: entry.value.path,
                artworkPath: null,
              ))
          .toList();
      
      // Update the music service with this directory's songs
      viewModel.songs.clear();
      viewModel.songs.addAll(directorySongs);
      
      // Play the selected song
      viewModel.playSong(startIndex);
      
      // Navigate to player
      Get.to(() => const PlayerView());
      
      print('Playing directory: ${dirInfo.name}, starting with song ${startIndex}');
    } catch (e) {
      print('Error playing directory songs: $e');
      Get.snackbar(
        'Error',
        'Could not play songs from this folder',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

class DirectoryDetailView extends StatelessWidget {
  final DirectoryInfo directoryInfo;

  const DirectoryDetailView({super.key, required this.directoryInfo});

  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _getFileNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  Song _createSongFromFile(File file, int index) {
    final fileName = _getFileName(file.path);
    final title = _getFileNameWithoutExtension(fileName);
    
    return Song(
      id: 'folder_${directoryInfo.name}_$index',
      title: title,
      artist: 'Unknown Artist',
      album: directoryInfo.name,
      duration: '0',
      uri: file.path,
      artworkPath: null,
    );
  }

  Future<void> _playFolderSong(int index) async {
    try {
      final viewModel = Get.find<MusicViewModel>();
      
      // Create Song objects for all files in this folder
      final folderSongs = directoryInfo.audioFiles
          .asMap()
          .entries
          .map((entry) => _createSongFromFile(entry.value, entry.key))
          .toList();
      
      // Update the music service with this folder's songs
      viewModel.songs.clear();
      viewModel.songs.addAll(folderSongs);
      
      // Play the selected song
      viewModel.playSong(index);
      
      // Navigate to player
      Get.to(() => const PlayerView());
      
      print('Playing folder song: ${folderSongs[index].title}');
    } catch (e) {
      print('Error playing folder song: $e');
      Get.snackbar(
        'Error',
        'Could not play the selected song',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(directoryInfo.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _playFolderSong(0), // Play first song
            tooltip: 'Play all',
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder info header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder, color: Colors.orange, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directoryInfo.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${directoryInfo.audioFileCount} audio files',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Play all button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _playFolderSong(0),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Files list
          Expanded(
            child: ListView.builder(
              itemCount: directoryInfo.audioFiles.length,
              itemBuilder: (context, index) {
                final file = directoryInfo.audioFiles[index];
                final fileName = _getFileName(file.path);
                final title = _getFileNameWithoutExtension(fileName);
                
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.blue),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Track ${index + 1}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: () => _playFolderSong(index),
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: () => _playFolderSong(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
