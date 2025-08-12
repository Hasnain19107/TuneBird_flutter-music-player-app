import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:metadata_god/metadata_god.dart';

import 'views/home/home_view.dart';
import 'services/music_service.dart';
import 'services/playlist_manager.dart';
import 'services/folder_data_service.dart';
import 'services/song_data_service.dart';
import 'viewmodels/music_viewmodel.dart';
import 'controllers/folder_controller.dart';
import 'controllers/songs_controller.dart';
import 'utils/theme_controller.dart';
import 'utils/theme.dart';
import 'views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize metadata parser for artwork-from-file support
    try {
      await MetadataGod.initialize();
    } catch (_) {}
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize folder data service
    await FolderDataService.init();

    // Initialize song data service
    await SongDataService.init();

    // Initialize and register services properly with better error handling
    final musicService = MusicService();
    try {
      await musicService.init();
    } catch (e) {
      print('MusicService initialization failed: $e');
      // Continue app startup even if music service fails
      // This allows the app to start and show error UI instead of crashing
    }
    Get.put(musicService);

    final playlistManager = PlaylistManager();
    await playlistManager.init();
    Get.put(playlistManager);

    // Initialize viewmodel after services
    Get.put(MusicViewModel());

    // Initialize folder controller (will load folders from cache)
    Get.put(FolderController());

    // Initialize songs controller (will load songs from cache)
    Get.put(SongsController());

    // Put ThemeController
    Get.put(ThemeController());

    runApp(const MyApp());
  } catch (e) {
    // Handle initialization errors gracefully
    print('Error during app initialization: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => GetMaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeController.themeMode.value,
      home: SplashWrapper(),
    ));
  }

}

class SplashWrapper extends StatefulWidget {
  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? const SplashScreen() : const HomeView();
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
