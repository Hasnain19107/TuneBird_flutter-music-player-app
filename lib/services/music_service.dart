import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';

class MusicService extends GetxService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final RxList<Song> songs = <Song>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isShuffleOn = false.obs;
  final RxBool isRepeatOn = false.obs;
  final RxDouble currentPosition = 0.0.obs;
  final RxDouble duration = 0.0.obs;
  Future<MusicService> init() async {
    try {
      // Don't load songs during initialization to avoid the plugin bug
      // Songs will be loaded later when permissions are properly granted
      songs.value = [];
      _setupPlayerListeners();
      _setupPlayerErrorHandlers();
      return this;
    } catch (e) {
      print('MusicService init error: $e');
      // Initialize with empty song list to prevent crashes
      songs.value = [];
      _setupPlayerListeners();
      _setupPlayerErrorHandlers();
      return this;
    }
  }

  Future<void> _loadSongs() async {
    try {
      print('Starting to load songs...');

      // First check if we can access the media library safely
      // This is a safer approach than directly querying
      bool canAccess = await _checkMediaAccess();
      if (!canAccess) {
        print('Cannot access media library - no permissions');
        songs.value = [];
        return;
      }

      final List<SongModel> deviceSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );

      songs.value = deviceSongs
          .where((song) => song.uri != null && song.uri!.isNotEmpty)
          .map((song) => Song.fromMap({
                'id': song.id,
                'title': song.title,
                'artist': song.artist ?? 'Unknown Artist',
                'album': song.album ?? 'Unknown Album',
                'duration': song.duration.toString(),
                'uri': song.uri!,
              }))
          .toList();

      print('Loaded ${songs.length} songs');
      if (songs.isNotEmpty) {
        print('Sample song URI: ${songs.first.uri}');
      }
    } catch (e) {
      print('Error loading songs: $e');
      // Set empty list if loading fails
      songs.value = [];
    }
  }

  // Safely check if we can access media without triggering the plugin bug
  Future<bool> _checkMediaAccess() async {
    try {
      // Use permission_handler to check status first
      var storageStatus = await Permission.storage.status;
      var audioStatus = await Permission.audio.status;

      // For Android 13+, we need different permissions
      if (audioStatus.isGranted || storageStatus.isGranted) {
        return true;
      }

      print('Media access not available - permissions not granted');
      return false;
    } catch (e) {
      print('Error checking media access: $e');
      return false;
    }
  }

  // Method to request permissions safely after app starts
  Future<bool> requestPermissionsIfNeeded() async {
    try {
      print('Requesting permissions if needed...');

      // Use permission_handler directly to avoid the on_audio_query bug
      var status = await Permission.storage.status;
      var audioStatus = await Permission.audio.status;

      bool needsPermission = !status.isGranted && !audioStatus.isGranted;

      if (needsPermission) {
        print('Requesting storage permission...');
        status = await Permission.storage.request();

        if (!status.isGranted) {
          print('Requesting audio permission...');
          audioStatus = await Permission.audio.request();
        }
      }

      bool hasPermission = status.isGranted || audioStatus.isGranted;
      print(
          'Permission status - Storage: ${status.isGranted}, Audio: ${audioStatus.isGranted}');

      if (hasPermission && songs.isEmpty) {
        print('Permission granted, loading songs...');
        // Add a delay to ensure the permission system is fully ready
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadSongs();
      }

      return hasPermission;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  void _setupPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });

    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position.inSeconds.toDouble();
    });

    _audioPlayer.durationStream.listen((totalDuration) {
      duration.value = totalDuration?.inSeconds.toDouble() ?? 0.0;
    });
  }

  Future<void> playSong(int index) async {
    if (index >= 0 && index < songs.length) {
      try {
        currentIndex.value = index;
        final song = songs[index];
        print('Attempting to play: ${song.title} with URI: ${song.uri}');

        // Use helper method to handle different URI formats
        await _setAudioSource(song.uri);
        await _audioPlayer.play();
        print('Successfully started playing: ${song.title}');
      } catch (e) {
        print('Error playing song ${songs[index].title}: $e');
      }
    }
  }

  // Helper method to handle different URI formats
  Future<void> _setAudioSource(String uri) async {
    try {
      if (uri.startsWith('content://')) {
        // For content URIs, use AudioSource.uri
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      } else if (uri.startsWith('file://') || uri.startsWith('/')) {
        // For file paths, use setFilePath
        final filePath = uri.startsWith('file://') ? uri.substring(7) : uri;
        await _audioPlayer.setFilePath(filePath);
      } else {
        // For other URIs, try setUrl
        await _audioPlayer.setUrl(uri);
      }
    } catch (e) {
      print('Error setting audio source with URI: $uri, Error: $e');
      rethrow;
    }
  }

  void togglePlay() {
    if (isPlaying.value) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  Future<void> nextSong() async {
    if (currentIndex.value < songs.length - 1) {
      await playSong(currentIndex.value + 1);
    }
  }

  Future<void> previousSong() async {
    if (currentIndex.value > 0) {
      await playSong(currentIndex.value - 1);
    }
  }

  void seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  void toggleShuffle() {
    isShuffleOn.value = !isShuffleOn.value;
    _audioPlayer.setShuffleModeEnabled(isShuffleOn.value);
  }

  void toggleRepeat() {
    isRepeatOn.value = !isRepeatOn.value;
    _audioPlayer.setLoopMode(isRepeatOn.value ? LoopMode.one : LoopMode.off);
  }

  // Add error handling for playback errors
  void _setupPlayerErrorHandlers() {
    _audioPlayer.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.idle) {
        isPlaying.value = false;
      }
    }, onError: (Object e, StackTrace st) {
      print('Playback error: $e');
      // Skip to next song if current song can't be played
      if (songs.isNotEmpty && currentIndex.value < songs.length - 1) {
        nextSong();
      }
    });
  }

  // Public method to manually trigger song loading
  Future<void> loadSongs() async {
    await _loadSongs();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
