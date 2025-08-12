import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
// Background playback removed (reverted)
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import 'song_data_service.dart';

class MusicService extends GetxService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Active playback queue (may be a subset like a folder)
  final RxList<Song> songs = <Song>[].obs;
  // Full scanned library for Songs tab display
  final RxList<Song> librarySongs = <Song>[].obs;
  // Original order of current playback queue for shuffle restore
  List<Song>? _originalOrder;
  // Flag indicating playback queue is a temporary (folder/playlist) queue, not the full library
  bool _usingTemporaryQueue = false;
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
  librarySongs.value = [];
  // AudioSession configuration removed in revert
      _setupPlayerListeners();
      _setupPlayerErrorHandlers();

      // Load cached songs immediately (no permissions required)
      // This makes the Songs tab render instantly on app start
      try {
        // SongDataService is initialized in main, but calling init() again is safe
        await SongDataService.init();
        final hasValidCache = await SongDataService.isCacheValid();
        final cached = await SongDataService.loadSongs();
        if (cached.isNotEmpty) {
          librarySongs.value = cached;
          songs.value = List<Song>.from(librarySongs); // initial playback queue mirrors library
          // If cache is invalid, we'll refresh after permissions later
          if (!hasValidCache) {
            // No-op here; refresh will happen after permission grant
          }
        }
      } catch (e) {
        // Ignore cache load errors to keep startup robust
      }
      return this;
    } catch (e) {
      print('MusicService init error: $e');
      // Initialize with empty song list to prevent crashes
  songs.value = [];
  librarySongs.value = [];
      _setupPlayerListeners();
      _setupPlayerErrorHandlers();
      return this;
    }
  }

  Future<void> _loadSongs() async {
    try {
  print('Starting to load songs (library scan)...');

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

      final scanned = deviceSongs
          .where((s) => s.uri != null && (s.uri?.isNotEmpty ?? false))
          .map((s) => Song.fromMap({
                'id': s.id,
                'title': s.title,
                'artist': s.artist ?? 'Unknown Artist',
                'album': s.album ?? 'Unknown Album',
                'duration': s.duration.toString(),
                'uri': s.uri!, // keep original (content://) for reliability
              }))
          .toList();
      librarySongs.value = scanned;
      if (!_usingTemporaryQueue) {
        songs.value = List<Song>.from(librarySongs);
      }

      // Reset saved order when freshly loading songs
      _originalOrder = null;

      print('Loaded ${librarySongs.length} songs');
      if (librarySongs.isNotEmpty) {
        print('First song uri sample: ${librarySongs.first.uri}');
      }

      // Persist latest scan to cache so subsequent app starts load instantly
      try {
  await SongDataService.saveSongs(librarySongs);
      } catch (e) {
        // Ignore cache save errors
      }
    } catch (e) {
      print('Error loading songs: $e');
      // Set empty list if loading fails
  songs.value = [];
  librarySongs.value = [];
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

      if (hasPermission) {
        // If we already have songs (likely from cache), only rescan if cache is invalid
        bool shouldRescan = false;
        try {
          final isValid = await SongDataService.isCacheValid();
          shouldRescan = !isValid || librarySongs.isEmpty;
        } catch (_) {
          shouldRescan = librarySongs.isEmpty;
        }

        if (shouldRescan) {
          print('Permission granted, refreshing song library from device...');
          // Add a delay to ensure the permission system is fully ready
          await Future.delayed(const Duration(milliseconds: 1000));
          await _loadSongs();
        } else {
          print('Using cached songs; skipping device rescan.');
        }
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
      if (state.processingState == ProcessingState.completed) {
        // Auto-advance or stop depending on repeat/shuffle
        if (isRepeatOn.value) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (currentIndex.value < songs.length - 1) {
          nextSong();
        } else {
          // Reached end
          _audioPlayer.stop();
        }
      }
    });

    // Keep current index synced if a playlist source used in future
    _audioPlayer.currentIndexStream.listen((i) {
      if (i != null && i >= 0) {
        currentIndex.value = i;
      }
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
        await _setAudioSource(song);
  await _audioPlayer.play();
  print('Successfully started playing: ${song.title}');
      } catch (e) {
  print('Error playing song ${songs[index].title}: $e');
      }
    }
  }

  // Helper method to handle different URI formats
  Future<void> _setAudioSource(Song song) async {
    try {
      final uri = song.uri;
      if (uri.startsWith('content://')) {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      } else if (uri.startsWith('file://') || uri.startsWith('/')) {
        final filePath = uri.startsWith('file://') ? uri.substring(7) : uri;
        await _audioPlayer.setFilePath(filePath);
      } else {
        await _audioPlayer.setUrl(uri);
      }
    } catch (e) {
      print('Error setting audio source with URI: ${song.uri}, Error: $e');
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
    final wasOn = isShuffleOn.value;
    isShuffleOn.value = !isShuffleOn.value;
    _audioPlayer.setShuffleModeEnabled(isShuffleOn.value);

  // Note: currently using single track sources; playlist shuffle support
  // would require rebuilding a ConcatenatingAudioSource with tags.

    if (songs.isEmpty) return;

    // Keep currently playing song reference to preserve it across reordering
    final current = (currentIndex.value >= 0 && currentIndex.value < songs.length)
        ? songs[currentIndex.value]
        : null;

    if (!wasOn && isShuffleOn.value) {
      // Turning shuffle ON: store original order and shuffle the list shown in UI
      _originalOrder = List<Song>.from(songs);
      final shuffled = List<Song>.from(songs);
      shuffled.shuffle();
      songs.value = shuffled;
    } else if (wasOn && !isShuffleOn.value) {
      // Turning shuffle OFF: restore the original order if available
      if (_originalOrder != null) {
        songs.value = List<Song>.from(_originalOrder!);
      }
      _originalOrder = null;
    }

    // Restore currentIndex to the same song if possible
    if (current != null) {
      final newIndex = songs.indexWhere((s) => s.id == current.id);
      if (newIndex != -1) {
        currentIndex.value = newIndex;
      } else {
        currentIndex.value = 0;
      }
    }
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

  // Replace full library; keeps playback queue in sync unless using a temporary queue
  void setLibrarySongs(List<Song> newSongs) {
    librarySongs.value = List<Song>.from(newSongs);
    if (!_usingTemporaryQueue) {
      songs.value = List<Song>.from(newSongs);
      // Adjust current index if out of range
      if (currentIndex.value >= songs.length) {
        currentIndex.value = 0;
      }
    }
    _originalOrder = null;
  }

  // Whether current playback queue is a temporary subset (e.g., folder)
  bool get isUsingTemporaryQueue => _usingTemporaryQueue;

  // Set a temporary playback queue without modifying the full librarySongs list
  Future<void> setTemporaryQueue(List<Song> queue, {int startIndex = 0}) async {
    _usingTemporaryQueue = true;
    songs.value = List<Song>.from(queue);
    _originalOrder = null;
    await playSong(startIndex);
  }

  // Restore playback queue to full library
  Future<void> restoreLibraryQueue({int? startIndex}) async {
    _usingTemporaryQueue = false;
    songs.value = List<Song>.from(librarySongs);
    _originalOrder = null;
    if (startIndex != null && startIndex >= 0 && startIndex < songs.length) {
      await playSong(startIndex);
    }
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
