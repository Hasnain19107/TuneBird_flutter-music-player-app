import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/music_viewmodel.dart';

class PlaylistView extends StatelessWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<MusicViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
      ),
      body: Obx(() => ReorderableListView.builder(
        itemCount: viewModel.songs.length,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = viewModel.songs.removeAt(oldIndex);
          viewModel.songs.insert(newIndex, item);
        },
        itemBuilder: (context, index) {
          final song = viewModel.songs[index];
          return ListTile(
            key: ValueKey(song.id),
            leading: const CircleAvatar(
              child: Icon(Icons.music_note),
            ),
            title: Text(song.title),
            subtitle: Text(song.artist),
            trailing: const Icon(Icons.drag_handle),
            onTap: () {
              viewModel.playSong(index);
              Get.back();
            },
          );
        },
      )),
    );
  }
}