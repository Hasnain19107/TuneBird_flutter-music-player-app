import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/music_viewmodel.dart';
import '../player/player_view.dart';

class SongsView extends StatelessWidget {
  const SongsView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();
    
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_note, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No songs found'),
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
}
