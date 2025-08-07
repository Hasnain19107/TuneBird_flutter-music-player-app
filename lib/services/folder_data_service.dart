import 'package:hive_flutter/hive_flutter.dart';
import '../models/directory_info_model.dart';
import 'dart:io';

class FolderDataService {
  static const String _boxName = 'folder_data';
  static Box<DirectoryInfoModel>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DirectoryInfoModelAdapter());
    }
    _box = await Hive.openBox<DirectoryInfoModel>(_boxName);
  }

  static Box<DirectoryInfoModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('FolderDataService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Save scanned directories
  static Future<void> saveDirectories(List<DirectoryInfo> directories) async {
    try {
      await box.clear(); // Clear old data
      
      final models = directories.map((dir) => DirectoryInfoModel.fromDirectoryInfo(dir)).toList();
      
      for (int i = 0; i < models.length; i++) {
        await box.put('dir_$i', models[i]);
      }
      
      // Save scan timestamp
      await box.put('last_scan_time', DirectoryInfoModel(
        path: '__metadata__',
        name: '__metadata__',
        audioFileCount: 0,
        audioFilePaths: [],
        lastScanned: DateTime.now(),
      ));
      
      print('Saved ${directories.length} directories to cache');
    } catch (e) {
      print('Error saving directories: $e');
    }
  }

  // Load cached directories
  static Future<List<DirectoryInfo>> loadDirectories() async {
    try {
      final List<DirectoryInfo> directories = [];
      
      for (final key in box.keys) {
        if (key.toString().startsWith('dir_')) {
          final model = box.get(key);
          if (model != null) {
            // Verify files still exist before adding
            final validFiles = <File>[];
            for (final filePath in model.audioFilePaths) {
              final file = File(filePath);
              if (await file.exists()) {
                validFiles.add(file);
              }
            }
            
            if (validFiles.isNotEmpty) {
              directories.add(DirectoryInfo(
                path: model.path,
                name: model.name,
                audioFileCount: validFiles.length,
                audioFiles: validFiles,
              ));
            }
          }
        }
      }
      
      print('Loaded ${directories.length} directories from cache');
      return directories;
    } catch (e) {
      print('Error loading directories: $e');
      return [];
    }
  }

  // Check if cache is valid (not older than 24 hours)
  static Future<bool> isCacheValid() async {
    try {
      final metadata = box.get('last_scan_time');
      if (metadata == null) return false;
      
      final lastScan = metadata.lastScanned;
      final now = DateTime.now();
      final difference = now.difference(lastScan);
      
      // Cache is valid for 24 hours
      return difference.inHours < 24;
    } catch (e) {
      print('Error checking cache validity: $e');
      return false;
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      await box.clear();
      print('Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Get cache info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final metadata = box.get('last_scan_time');
      if (metadata == null) {
        return {'hasCache': false, 'lastScan': null, 'count': 0};
      }

      final count = box.keys.where((key) => key.toString().startsWith('dir_')).length;
      
      return {
        'hasCache': true,
        'lastScan': metadata.lastScanned,
        'count': count,
        'isValid': await isCacheValid(),
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {'hasCache': false, 'lastScan': null, 'count': 0};
    }
  }
}
