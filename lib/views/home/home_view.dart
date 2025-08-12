import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/theme_controller.dart';
import '../folder/folder_view.dart';
// removed unused imports
import '../../services/music_service.dart';
import '../common/mini_player.dart';
import '../songs/songs_view_new.dart';
import '../playlists/playlists_view.dart';
import '../search/search_view.dart';
import '../../services/artwork_cache_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Request permissions after the widget is built to avoid the crash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsDelayed();
    });
  }

  Future<void> _requestPermissionsDelayed() async {
    try {
      final musicService = Get.find<MusicService>();
      await Future.delayed(
          const Duration(seconds: 2)); // Wait for app to fully load

      print('Requesting permissions from HomeView...');
      bool success = await musicService.requestPermissionsIfNeeded();

      if (success) {
        print('Permissions granted successfully');
    // Warm up artwork for first visible songs to remove initial delay
    final ids = musicService.songs
      .map((s) => int.tryParse(s.id))
      .whereType<int>();
    // ignore: unawaited_futures
    ArtworkCacheService.warmUp(ids);
      } else {
        print('Permissions were not granted');
      }
    } catch (e) {
      print('Error requesting permissions from HomeView: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
  // MusicViewModel still registered globally; no direct usage needed here now.
    final themeController = Get.find<ThemeController>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          title: const Text(
            'Music',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Get.to(() => const SearchView()),
            ),
            IconButton(
              icon: Obx(() => Icon(
                themeController.themeMode.value == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              )),
              tooltip: 'Toggle Theme',
              onPressed: themeController.toggleTheme,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Playlist'),
              Tab(text: 'Folders'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
    body: Column(
          children: [
            Divider(height: 1, color: Colors.white.withOpacity(0.06)),
            Expanded(
              child: TabBarView(
                children: const [
                  SongsView(),
                  PlaylistsView(),
                  FolderView(),
                  Center(child: Text('Albums')),
                  Center(child: Text('Artists')),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
  // Removed inline Songs tab implementation; now using dedicated SongsView.

  // Date formatting removed (unused after refactor).

  // Removed custom mini player; using global MiniPlayer component.
}

// Removed _MiniMarqueeText (marquee logic now centralized in global mini player if needed).
