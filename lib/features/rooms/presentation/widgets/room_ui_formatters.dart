import '../../../rankings/domain/rank_tier.dart';

abstract final class RoomUiFormatters {
  static String dateRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final isToday =
        start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        start.year == tomorrow.year &&
        start.month == tomorrow.month &&
        start.day == tomorrow.day;

    final weekday = switch (start.weekday) {
      DateTime.monday => 'Thứ 2',
      DateTime.tuesday => 'Thứ 3',
      DateTime.wednesday => 'Thứ 4',
      DateTime.thursday => 'Thứ 5',
      DateTime.friday => 'Thứ 6',
      DateTime.saturday => 'Thứ 7',
      DateTime.sunday => 'Chủ Nhật',
      _ => '',
    };

    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    final isOvernight =
        end.year != start.year || end.month != start.month || end.day != start.day;
    final overnightTag = isOvernight ? ' (+1 ngày)' : '';

    final durationHours = end.difference(start).inHours;
    final durationMins = end.difference(start).inMinutes % 60;
    final durationStr =
        durationHours > 0 && durationMins > 0
            ? '${durationHours}h${durationMins}p'
            : durationHours > 0
            ? '${durationHours}h'
            : '${durationMins}p';

    if (isToday) {
      return 'Hôm nay, $startTime–$endTime$overnightTag ($durationStr)';
    } else if (isTomorrow) {
      return 'Ngày mai, $startTime–$endTime$overnightTag ($durationStr)';
    } else {
      return '$weekday, ${start.day}/${start.month} • $startTime–$endTime$overnightTag ($durationStr)';
    }
  }

  static String deadline(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;

    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    if (isToday) {
      return 'Trước $timeStr hôm nay';
    } else if (isTomorrow) {
      return 'Trước $timeStr ngày mai';
    } else {
      return 'Trước $timeStr, $dateStr';
    }
  }

  static String currency(int amount) {
    if (amount <= 0) return 'Miễn phí';
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()}đ';
  }

  static String skillRange(int minElo, int maxElo) {
    if (minElo <= 0 && maxElo >= 2000) return 'Mọi trình độ';
    final minTier = RankTier.fromElo(minElo.clamp(0, 2500));
    final maxTier = RankTier.fromElo(maxElo.clamp(0, 2500));
    if (minTier == maxTier) return '${minTier.label} ($minElo–$maxElo)';
    return '${minTier.label} – ${maxTier.label} ($minElo–$maxElo)';
  }
}
