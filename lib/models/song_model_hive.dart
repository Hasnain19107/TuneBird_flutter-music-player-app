import 'package:hive_flutter/hive_flutter.dart';
import '../models/song_model.dart';

part 'song_model_hive.g.dart';

@HiveType(typeId: 1)
class SongModelHive extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String artist;
  
  @HiveField(3)
  final String album;
  
  @HiveField(4)
  final String duration;
  
  @HiveField(5)
  final String uri;
  
  @HiveField(6)
  final String? artworkPath;
  
  @HiveField(7)
  final DateTime lastScanned;

  SongModelHive({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.artworkPath,
    required this.lastScanned,
  });

  // Convert to Song for UI
  Song toSong() {
    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      uri: uri,
      artworkPath: artworkPath,
    );
  }

  // Create from Song
  static SongModelHive fromSong(Song song) {
    return SongModelHive(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      uri: song.uri,
      artworkPath: song.artworkPath,
      lastScanned: DateTime.now(),
    );
  }
}
