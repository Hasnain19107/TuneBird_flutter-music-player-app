/// Generic formatting helpers (durations, strings etc.)
class FormatUtils {
  /// Format milliseconds (or a numeric string) to mm:ss.
  /// Accepts already formatted "mm:ss" and returns as-is.
  static String formatMmSs(dynamic value) {
    if (value == null) return '--:--';
    if (value is String) {
      if (value.contains(':')) return value; // already formatted
      final ms = int.tryParse(value);
      if (ms == null) return '--:--';
      return _fromMilliseconds(ms);
    }
    if (value is int) return _fromMilliseconds(value);
    if (value is double) return _fromMilliseconds(value.toInt());
    return '--:--';
  }

  static String _fromMilliseconds(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
