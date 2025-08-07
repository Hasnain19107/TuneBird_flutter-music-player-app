import 'package:get/get.dart';
import '../models/playlist_model.dart';

class PlaylistManager extends GetxService {
  final RxList<Playlist> playlists = <Playlist>[].obs;
  
  Future<PlaylistManager> init() async {
    // Initialize with default playlists
    playlists.add(Playlist(
      id: 'favorites',
      name: 'Favorites',
      songIds: [],
    ));
    return this;
  }

  void createPlaylist(String name) {
    final playlist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
    );
    playlists.add(playlist);
  }

  void addSongToPlaylist(String playlistId, String songId) {
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songIds.contains(songId)) {
      final index = playlists.indexWhere((p) => p.id == playlistId);
      final updatedPlaylist = Playlist(
        id: playlist.id,
        name: playlist.name,
        songIds: [...playlist.songIds, songId],
      );
      playlists[index] = updatedPlaylist;
    }
  }

  void removeSongFromPlaylist(String playlistId, String songId) {
    final playlist = playlists.firstWhere((p) => p.id == playlistId);
    final index = playlists.indexWhere((p) => p.id == playlistId);
    final updatedPlaylist = Playlist(
      id: playlist.id,
      name: playlist.name,
      songIds: playlist.songIds.where((id) => id != songId).toList(),
    );
    playlists[index] = updatedPlaylist;
  }

  void deletePlaylist(String playlistId) {
    playlists.removeWhere((p) => p.id == playlistId);
  }
}