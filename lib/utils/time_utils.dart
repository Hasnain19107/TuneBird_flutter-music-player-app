/// Utility helpers for time calculations and human friendly formatting.
class TimeUtils {
  /// Returns a short human readable 'time ago' string relative to now.
  /// Examples: Just now, 5m ago, 3h ago, 2d ago
  static String timeAgo(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
