import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/song_model.dart';
import '../../services/music_service.dart';
import 'global_songs_list.dart';

/// High-level reusable songs list section that can be used across tabs.
/// It optionally shows a header (count, last scan) and action bar (shuffle/play).
class SongListView extends StatelessWidget {
  final String titleSingular;
  final bool showActions;
  final List<Song>? customSongs; // if provided, renders custom list
  final VoidCallback? onRefresh;
  final String? lastScanText;
  final bool isLoading;
  final bool isScanning;
  final VoidCallback? onShuffle;
  final VoidCallback? onPlayAll;
  final String? query;
  final void Function(Song song, int index)? onSongTap;
  final Widget? header; // optional custom header (replaces default header/count)

  const SongListView({
    super.key,
    this.titleSingular = 'Songs',
    this.showActions = true,
    this.customSongs,
    this.onRefresh,
    this.lastScanText,
    this.isLoading = false,
    this.isScanning = false,
    this.onShuffle,
    this.onPlayAll,
    this.query,
    this.onSongTap,
  this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLibrary = customSongs == null;
    final musicService = Get.isRegistered<MusicService>() ? Get.find<MusicService>() : null;
    final count = customSongs?.length ?? (musicService?.librarySongs.length ?? 0);

    return Column(
      children: [
        if (header != null)
          header!
        else
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      isScanning ? 'Scanning...' : '$count $titleSingular',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (onRefresh != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: isScanning ? null : onRefresh,
                        tooltip: 'Refresh',
                      ),
                  ],
                ),
                if (!isScanning && count > 0 && (lastScanText?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Last scanned: $lastScanText',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        if (showActions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShuffle,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlayAll,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (showActions) const SizedBox(height: 16),
        Expanded(
          child: GlobalSongsList(
            source: isLibrary ? SongSource.library : SongSource.custom,
            customSongs: customSongs,
            isTemporaryQueue: !isLibrary,
            query: query,
            onSongTap: onSongTap,
          ),
        ),
      ],
    );
  }
}
