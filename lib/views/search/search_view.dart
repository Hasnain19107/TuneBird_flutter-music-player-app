import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/services/playlist_manager.dart';

import '../../viewmodels/music_viewmodel.dart';
import '../../utils/search_utils.dart';
import '../player/player_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final RxList _searchResults = [].obs;
  final RxBool _isSearchEmpty = true.obs;
  late final MusicViewModel _viewModel;
  late final PlaylistManager _playlistManager;

  @override
  void initState() {
    super.initState();
    _viewModel = Get.find<MusicViewModel>();
    _playlistManager = Get.find<PlaylistManager>();
    _searchController.addListener(_performSearch);
  }

  void _performSearch() {
    _isSearchEmpty.value = _searchController.text.isEmpty;

    if (_searchController.text.isEmpty) {
      _searchResults.clear();
    } else {
      _searchResults.value = SearchUtils.searchSongs(
        _viewModel.songs,
        _searchController.text,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists, albums...',
            border: InputBorder.none,
          ),
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_isSearchEmpty.value) {
          return const Center(
            child: Text('Search for songs, artists, or albums'),
          );
        }

        if (_searchResults.isEmpty) {
          return const Center(
            child: Text('No results found'),
          );
        }

        return ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final song = _searchResults[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.music_note),
              ),
              title: Text(song.title),
              subtitle: Text(song.artist),
              onTap: () {
                final originalIndex = _viewModel.songs.indexWhere(
                  (s) => s.id == song.id,
                );
                _viewModel.playSong(originalIndex);
                Get.to(() => const PlayerView());
              },
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showSongOptions(context, song),
              ),
            );
          },
        );
      }),
    );
  }

  void _showSongOptions(BuildContext context, song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Play'),
            onTap: () {
              final originalIndex = _viewModel.songs.indexWhere(
                (s) => s.id == song.id,
              );
              _viewModel.playSong(originalIndex);
              Get.back();
              Get.to(() => const PlayerView());
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to playlist'),
            onTap: () {
              Get.back();
              _showAddToPlaylistDialog(context, song);
            },
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() => ListView.builder(
                itemCount: _playlistManager.playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlistManager.playlists[index];
                  return ListTile(
                    title: Text(playlist.name),
                    onTap: () {
                      _playlistManager.addSongToPlaylist(playlist.id, song.id);
                      Get.back();
                      Get.snackbar(
                        'Added to Playlist',
                        'Song added to ${playlist.name}',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  );
                },
              )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
