import 'package:hive/hive.dart';
import 'dart:io';

part 'directory_info_model.g.dart';

@HiveType(typeId: 0)
class DirectoryInfoModel extends HiveObject {
  @HiveField(0)
  final String path;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final int audioFileCount;
  
  @HiveField(3)
  final List<String> audioFilePaths;
  
  @HiveField(4)
  final DateTime lastScanned;

  DirectoryInfoModel({
    required this.path,
    required this.name,
    required this.audioFileCount,
    required this.audioFilePaths,
    required this.lastScanned,
  });

  // Convert to DirectoryInfo for UI
  DirectoryInfo toDirectoryInfo() {
    return DirectoryInfo(
      path: path,
      name: name,
      audioFileCount: audioFileCount,
      audioFiles: audioFilePaths.map((path) => File(path)).toList(),
    );
  }

  // Create from DirectoryInfo
  static DirectoryInfoModel fromDirectoryInfo(DirectoryInfo dirInfo) {
    return DirectoryInfoModel(
      path: dirInfo.path,
      name: dirInfo.name,
      audioFileCount: dirInfo.audioFileCount,
      audioFilePaths: dirInfo.audioFiles.map((file) => file.path).toList(),
      lastScanned: DateTime.now(),
    );
  }
}

// Keep the original DirectoryInfo class for UI compatibility
class DirectoryInfo {
  final String path;
  final String name;
  final int audioFileCount;
  final List<File> audioFiles;

  DirectoryInfo({
    required this.path,
    required this.name,
    required this.audioFileCount,
    required this.audioFiles,
  });
}
