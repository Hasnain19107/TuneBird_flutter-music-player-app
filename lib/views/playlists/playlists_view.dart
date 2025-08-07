import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/playlist_manager.dart';
import 'playlist_details_view.dart';

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistManager = Get.find<PlaylistManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: Obx(() => ListView.builder(
        itemCount: playlistManager.playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlistManager.playlists[index];
          return ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(playlist.name),
            subtitle: Text('${playlist.songIds.length} songs'),
            trailing: playlist.id != 'favorites'
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => playlistManager.deletePlaylist(playlist.id),
                  )
                : null,
            onTap: () => Get.to(() => PlaylistDetailsView(playlist: playlist)),
          );
        },
      )),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Playlist Name',
            hintText: 'Enter playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Get.find<PlaylistManager>().createPlaylist(nameController.text);
                Get.back();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}