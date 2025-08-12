import 'package:get/get.dart';
import '../services/music_service.dart';
import '../models/song_model.dart';
import '../utils/format_utils.dart';

class MusicViewModel extends GetxController {
  late final MusicService _musicService;

  @override
  void onInit() {
    super.onInit();
    try {
      _musicService = Get.find<MusicService>();
    } catch (e) {
      print('MusicService not found: $e');
      // Create a dummy service to prevent crashes
      _musicService = MusicService();
    }
  }

  RxList<Song> get songs => _musicService.songs;
  RxList<Song> get librarySongs => _musicService.librarySongs;
  bool get isUsingTemporaryQueue => _musicService.isUsingTemporaryQueue;
  RxInt get currentIndex => _musicService.currentIndex;
  RxBool get isPlaying => _musicService.isPlaying;
  RxBool get isShuffleOn => _musicService.isShuffleOn;
  RxBool get isRepeatOn => _musicService.isRepeatOn;
  RxDouble get currentPosition => _musicService.currentPosition;
  RxDouble get duration => _musicService.duration;

  Song? get currentSong =>
      currentIndex.value < songs.length ? songs[currentIndex.value] : null;

  String formatDuration(double seconds) => FormatUtils.formatMmSs((seconds * 1000).toInt());

  void playSong(int index) => _musicService.playSong(index);
  void togglePlay() => _musicService.togglePlay();
  void nextSong() => _musicService.nextSong();
  void previousSong() => _musicService.previousSong();
  void seekTo(Duration position) => _musicService.seekTo(position);
  void toggleShuffle() => _musicService.toggleShuffle();
  void toggleRepeat() => _musicService.toggleRepeat();
}
