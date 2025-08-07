import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../viewmodels/music_viewmodel.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Get.back(),
        ),
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            onPressed: () {
              // Navigate to playlist
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Album Art
            Container(
              width: Get.width * 0.8,
              height: Get.width * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.music_note, size: 80),
            ),

            // Song Info
            Column(
              children: [
                Obx(() => Text(
                  viewModel.currentSong?.title ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                )),
                const SizedBox(height: 8),
                Obx(() => Text(
                  viewModel.currentSong?.artist ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )),
              ],
            ),

            // Progress Bar
            Obx(() => ProgressBar(
              progress: Duration(seconds: viewModel.currentPosition.value.toInt()),
              total: Duration(seconds: viewModel.duration.value.toInt()),
              onSeek: (duration) => viewModel.seekTo(duration),
              timeLabelTextStyle: const TextStyle(color: Colors.white),
            )),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(() => IconButton(
                  icon: Icon(
                    viewModel.isShuffleOn.value 
                        ? Icons.shuffle_on_outlined
                        : Icons.shuffle,
                    color: viewModel.isShuffleOn.value 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  onPressed: viewModel.toggleShuffle,
                )),
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: viewModel.previousSong,
                ),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: Obx(() => IconButton(
                    icon: Icon(
                      viewModel.isPlaying.value 
                          ? Icons.pause 
                          : Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                    onPressed: viewModel.togglePlay,
                  )),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: viewModel.nextSong,
                ),
                Obx(() => IconButton(
                  icon: Icon(
                    viewModel.isRepeatOn.value 
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: viewModel.isRepeatOn.value 
                        ? Theme.of(context).primaryColor 
                        : null,
                  ),
                  onPressed: viewModel.toggleRepeat,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}