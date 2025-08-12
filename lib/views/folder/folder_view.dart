import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/folder_controller.dart';
import '../../models/directory_info_model.dart';
import '../player/player_view.dart';
import '../common/mini_player.dart';
import '../common/song_list_view.dart';
import '../../services/music_service.dart';
import '../../models/song_model.dart';

class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final folderController = Get.find<FolderController>();

    return Obx(() {
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
                      folderController.isScanning.value 
                          ? 'Scanning...' 
                          : '${folderController.audioDirectories.length} Folders',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: folderController.isScanning.value 
                          ? null 
                          : () => folderController.refreshFolders(),
                      tooltip: 'Refresh folders',
                    ),
                  ],
                ),
                if (!folderController.isScanning.value && 
                    folderController.audioDirectories.isNotEmpty &&
                    folderController.lastScanTime.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Last scanned: ${folderController.lastScanTime.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: folderController.isScanning.value
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(folderController.scanStatus.value.isEmpty 
                            ? 'Scanning...' 
                            : folderController.scanStatus.value),
                      ],
                    ),
                  )
                : folderController.audioDirectories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No audio folders found'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => folderController.refreshFolders(),
                              child: const Text('Scan Again'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: folderController.audioDirectories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final dir = folderController.audioDirectories[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _openDirectory(context, dir),
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[700],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.folder, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 16),
                                  // Texts
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dir.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dir.audioFileCount == 1
                                              ? '1 song'
                                              : '${dir.audioFileCount} songs',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // More / play quick actions
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    splashRadius: 20,
                                    onPressed: () async {
                                      // Placeholder for future actions (play all, add to playlist, etc.)
                                      await folderController.playDirectory(dir, startIndex: 0);
                                      Get.to(() => const PlayerView());
                                    },
                                    tooltip: 'Play / Options',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }

  void _openDirectory(BuildContext context, DirectoryInfo dirInfo) {
    Get.to(() => DirectoryDetailView(directoryInfo: dirInfo));
  }

  // Removed playback logic; now handled by controller.
}

// Simplified, controller-driven detail view
class DirectoryDetailView extends StatefulWidget {
  final DirectoryInfo directoryInfo;
  const DirectoryDetailView({super.key, required this.directoryInfo});

  @override
  State<DirectoryDetailView> createState() => _DirectoryDetailViewState();
}

class _DirectoryDetailViewState extends State<DirectoryDetailView> {
  late List<Song> _folderSongs;

  @override
  void initState() {
    super.initState();
    final folderController = Get.find<FolderController>();
    _folderSongs = folderController.buildSongsForDirectory(widget.directoryInfo);
  }

  // _refreshSongs removed (not currently used). Add if pull-to-refresh needed later.

  @override
  Widget build(BuildContext context) {
    final folderController = Get.find<FolderController>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.directoryInfo.name)),
      body: Column(
        children: [
          Expanded(
            child: SongListView(
              titleSingular: 'Songs',
              customSongs: _folderSongs,
              showActions: true,
              header: Container(
                padding: const EdgeInsets.fromLTRB(16,16,16,8),
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
                          Text(widget.directoryInfo.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_folderSongs.length} songs', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      tooltip: 'Play All',
                      onPressed: () async {
                        await folderController.playDirectory(widget.directoryInfo, startIndex: 0);
                        Get.to(() => const PlayerView());
                      },
                    )
                  ],
                ),
              ),
              onShuffle: () async {
                final songs = folderController.buildSongsForDirectory(widget.directoryInfo);
                songs.shuffle();
                final ms = Get.find<MusicService>();
                await ms.setTemporaryQueue(songs, startIndex: 0);
                setState(() { _folderSongs = songs; });
              },
              onPlayAll: () async {
                await folderController.playDirectory(widget.directoryInfo, startIndex: 0);
                Get.to(() => const PlayerView());
              },
              onSongTap: (song, idx) async {
                await folderController.playSongInDirectory(widget.directoryInfo, idx);
                Get.to(() => const PlayerView());
              },
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
