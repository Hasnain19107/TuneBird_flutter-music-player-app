import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/playlist_model.dart';
import '../../services/playlist_manager.dart';
import '../../viewmodels/music_viewmodel.dart';

class PlaylistDetailsView extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailsView({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final musicViewModel = Get.find<MusicViewModel>();
    final playlistManager = Get.find<PlaylistManager>();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSongsDialog(context, musicViewModel, playlistManager),
          ),
        ],
      ),
      body: Obx(() {
        final playlistSongs = musicViewModel.songs
            .where((song) => playlist.songIds.contains(song.id))
            .toList();

        if (playlistSongs.isEmpty) {
          return const Center(
            child: Text('No songs in this playlist'),
          );
        }

        return ListView.builder(
          itemCount: playlistSongs.length,
          itemBuilder: (context, index) {
            final song = playlistSongs[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.music_note),
              ),
              title: Text(song.title),
              subtitle: Text(song.artist),
              trailing: IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => playlistManager.removeSongFromPlaylist(
                  playlist.id,
                  song.id,
                ),
              ),
              onTap: () {
                final originalIndex = musicViewModel.songs.indexWhere(
                  (s) => s.id == song.id,
                );
                musicViewModel.playSong(originalIndex);
              },
            );
          },
        );
      }),
    );
  }

  void _showAddSongsDialog(
    BuildContext context,
    MusicViewModel musicViewModel,
    PlaylistManager playlistManager,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: musicViewModel.songs.length,
            itemBuilder: (context, index) {
              final song = musicViewModel.songs[index];
              final isInPlaylist = playlist.songIds.contains(song.id);
              
              return ListTile(
                title: Text(song.title),
                subtitle: Text(song.artist),
                trailing: isInPlaylist
                    ? const Icon(Icons.check)
                    : IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          playlistManager.addSongToPlaylist(
                            playlist.id,
                            song.id,
                          );
                        },
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}