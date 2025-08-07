class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String uri;
  final String? artworkPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.artworkPath,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'].toString(),
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown Album',
      duration: map['duration'] ?? '0',
      uri: map['uri'] ?? '',
      artworkPath: map['artworkPath'],
    );
  }
}