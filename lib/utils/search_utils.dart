import '../models/song_model.dart';

class SearchUtils {
  static List<Song> searchSongs(List<Song> songs, String query) {
    final lowercaseQuery = query.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(lowercaseQuery) ||
          song.artist.toLowerCase().contains(lowercaseQuery) ||
          song.album.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}