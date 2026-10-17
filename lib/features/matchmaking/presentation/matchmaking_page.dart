import 'package:flutter/material.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/match_room.dart';

class MatchmakingPage extends StatelessWidget {
  const MatchmakingPage({
    super.key,
    required this.rooms,
    required this.userId,
    required this.onJoin,
    required this.onRefresh,
    this.joiningRoomId,
  });
  final Future<List<MatchRoom>> rooms;
  final String? userId, joiningRoomId;
  final void Function(MatchRoom) onJoin;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => AsyncPanel<List<MatchRoom>>(
    future: rooms,
    onRetry: onRefresh,
    builder: (items) => PageContent(
      children: [
        Text(
          'Tìm đồng đội. Lên sân.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Khoảng cách tương đối • Sân công cộng',
          style: AppTokens.label,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Cập nhật kèo đấu'),
          ),
        ),
        if (items.isEmpty) const Text('Chưa có kèo. Hãy tạo kèo đầu tiên.'),
        for (final room in items)
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CÒN ${room.availableSlots} CHỖ', style: AppTokens.metric),
                const SizedBox(height: 12),
                Text(
                  room.courtName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${room.startsAt.day}/${room.startsAt.month} • ${TimeOfDay.fromDateTime(room.startsAt).format(context)}',
                ),
                if (room.distanceKm != null)
                  Text('Cách ${room.distanceKm} km', style: AppTokens.label),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed:
                      joiningRoomId != null ||
                          room.availableSlots == 0 ||
                          room.playerIds.contains(userId)
                      ? null
                      : () => onJoin(room),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    joiningRoomId == room.id
                        ? 'ĐANG VÀO KÈO…'
                        : room.playerIds.contains(userId)
                        ? 'ĐÃ THAM GIA'
                        : room.availableSlots == 0
                        ? 'ĐỦ NGƯỜI'
                        : 'VÀO KÈO',
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
