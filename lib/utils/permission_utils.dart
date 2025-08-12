import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permission helpers so logic is not duplicated across controllers/services.
class PermissionUtils {
  /// Request audio/storage permissions suitable for Android or return true for other platforms.
  static Future<bool> requestAudioPermissions() async {
    try {
      if (Platform.isAndroid) {
        var audioStatus = await Permission.audio.status;
        if (audioStatus.isDenied) {
          audioStatus = await Permission.audio.request();
        }
        if (audioStatus.isGranted) return true;

        var storageStatus = await Permission.storage.status;
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }
        return storageStatus.isGranted;
      }
      return true; // iOS & others – permissions handled by system
    } catch (_) {
      return false;
    }
  }

  /// Determine if we already have audio permission without prompting.
  static Future<bool> hasAudioPermission() async {
    try {
      if (Platform.isAndroid) {
        final a = await Permission.audio.status;
        final s = await Permission.storage.status;
        return a.isGranted || s.isGranted;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
