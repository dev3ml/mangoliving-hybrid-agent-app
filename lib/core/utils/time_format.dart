import 'package:intl/intl.dart';

/// Date / greeting helpers for Overview (web `overview-page.tsx`).
abstract final class TimeFormat {
  static String greeting([DateTime? now]) {
    final int hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String todayLabel([DateTime? now]) {
    return DateFormat('EEEE, MMMM d').format(now ?? DateTime.now());
  }

  static String relative(String? iso, [DateTime? now]) {
    if (iso == null || iso.isEmpty) return '';
    final DateTime? then = DateTime.tryParse(iso);
    if (then == null) return '';
    final Duration diff = (now ?? DateTime.now()).difference(then);
    final int sec = diff.inSeconds < 1 ? 1 : diff.inSeconds;
    if (sec < 60) return 'just now';
    final int min = sec ~/ 60;
    if (min < 60) return '${min}m ago';
    final int hr = min ~/ 60;
    if (hr < 24) return '${hr}h ago';
    final int day = hr ~/ 24;
    if (day < 7) return '${day}d ago';
    return DateFormat('MMM d').format(then);
  }

  static String showingDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Date to confirm';
    final DateTime? date = DateTime.tryParse(iso);
    if (date == null) return 'Date to confirm';
    return DateFormat('E, MMM d, h:mm a').format(date.toLocal());
  }

  static String monthShort(DateTime date) => DateFormat('MMM').format(date);

  static String messageTime(String? iso, [DateTime? now]) {
    if (iso == null || iso.isEmpty) return '';
    final DateTime? date = DateTime.tryParse(iso);
    if (date == null) return '';
    final DateTime local = date.toLocal();
    final DateTime clock = now ?? DateTime.now();
    final bool sameDay = local.year == clock.year &&
        local.month == clock.month &&
        local.day == clock.day;
    if (sameDay) return DateFormat.jm().format(local);
    return DateFormat.MMMd().format(local);
  }

  static String lastActiveLabel(int timestampMs, [DateTime? now]) {
    if (timestampMs <= 0) return 'Never';
    return relative(
      DateTime.fromMillisecondsSinceEpoch(timestampMs).toIso8601String(),
      now,
    );
  }

  static String unreadLabel(int count) {
    if (count <= 0) return '';
    return count > 99 ? '99+' : '$count';
  }

  static String attentionCopy(int count) {
    if (count <= 0) {
      return "You're all caught up. Here's a snapshot of your business.";
    }
    final String noun = count == 1 ? 'item' : 'items';
    return 'You have $count $noun that need your attention today.';
  }
}
