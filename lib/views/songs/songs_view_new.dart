import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/songs_controller.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../../services/music_service.dart';
import '../player/player_view.dart';
import '../common/song_list_view.dart';

class SongsView extends StatelessWidget {
  const SongsView({super.key});

  @override
  Widget build(BuildContext context) {
    final songsController = Get.find<SongsController>();
    final musicViewModel = Get.find<MusicViewModel>();

    return Obx(() {
      // Show initialization loading only if not initialized and not scanning
      if (!songsController.isInitialized.value && !songsController.isScanning.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return SongListView(
        titleSingular: 'Songs',
        isLoading: !songsController.isInitialized.value && !songsController.isScanning.value,
        isScanning: songsController.isScanning.value,
        lastScanText: songsController.lastScanTime.value,
        onRefresh: songsController.refreshSongs,
        onShuffle: () async {
          if (!Get.isRegistered<MusicService>()) return;
          final ms = Get.find<MusicService>();
          if (ms.librarySongs.isEmpty) return;
          // Ensure library queue active (restore if temporary)
          if (ms.isUsingTemporaryQueue) {
            await ms.restoreLibraryQueue(startIndex: 0);
          }
            if (!ms.isShuffleOn.value) {
              ms.toggleShuffle();
            } else {
              // If already shuffled, re-shuffle to get a new order
              ms.toggleShuffle();
              ms.toggleShuffle();
            }
          await ms.playSong(0);
        },
        onPlayAll: () {
          if (songsController.songs.isNotEmpty) {
            musicViewModel.playSong(0);
            Get.to(() => const PlayerView());
          }
        },
        onSongTap: (song, index) {
          musicViewModel.playSong(index);
          Get.to(() => const PlayerView());
        },
      );
    });
  }

}
