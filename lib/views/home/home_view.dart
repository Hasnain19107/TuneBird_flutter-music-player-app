import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../../utils/theme_controller.dart';
import '../folder/folder_view.dart';
import '../songs/songs_view.dart';
import '../favourite/favourite_view.dart';
import '../../services/music_service.dart';
import '../player/player_view.dart';
import '../playlists/playlists_view.dart';
import '../search/search_view.dart';

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
      } else {
        print('Permissions were not granted');
      }
    } catch (e) {
      print('Error requesting permissions from HomeView: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();
    final themeController = Get.find<ThemeController>();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          title: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.blue, Colors.cyan],
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
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
            Expanded(
              child: TabBarView(
                children: [
                  // Songs Tab
                  _buildSongsView(viewModel),
                  // Playlist Tab
                  const PlaylistsView(),
                  // Folders Tab
                  const FolderView(),
                  // Albums Tab (placeholder)
                  const Center(child: Text('Albums')),
                  // Artists Tab (placeholder)
                  const Center(child: Text('Artists')),
                ],
              ),
            ),
            // Mini Player
            Obx(() {
              if (viewModel.currentSong != null) {
                return _buildMiniPlayer(viewModel);
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsView(MusicViewModel viewModel) {
    return Column(
      children: [
        // Song count and buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Obx(() => Text(
                '${viewModel.songs.length} Songs ${viewModel.songs.isEmpty ? '(Scanning...)' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              )),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.view_list),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Shuffle and Play buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (viewModel.songs.isNotEmpty) {
                      viewModel.toggleShuffle();
                    }
                  },
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (viewModel.songs.isNotEmpty) {
                      viewModel.playSong(0);
                      Get.to(() => const PlayerView());
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Songs list
        Expanded(
          child: Obx(() {
            if (viewModel.songs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No songs found'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _requestPermissionsDelayed,
                      child: const Text('Grant Permissions'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: viewModel.songs.length,
              itemBuilder: (context, index) {
                final song = viewModel.songs[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[800],
                    ),
                    child: song.artworkPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.artworkPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.music_note, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.music_note, color: Colors.grey),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '320K',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  onTap: () {
                    viewModel.playSong(index);
                    Get.to(() => const PlayerView());
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildMiniPlayer(MusicViewModel viewModel) {
    return GestureDetector(
      onTap: () => Get.to(() => const PlayerView()),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album Art
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: viewModel.currentSong?.artworkPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        viewModel.currentSong!.artworkPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.music_note, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.music_note, color: Colors.grey),
            ),
            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.currentSong?.title ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    viewModel.currentSong?.artist ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Control Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Obx(() => Icon(
                        viewModel.isPlaying.value ? Icons.pause : Icons.play_arrow,
                      )),
                  onPressed: viewModel.togglePlay,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: viewModel.nextSong,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
