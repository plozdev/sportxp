import 'package:flutter/material.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../../core/theme/app_theme.dart';
import '../application/match_controller.dart';

class MatchmakingPage extends StatelessWidget {
  const MatchmakingPage({super.key, required this.controller});
  final MatchController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PageContent(
      children: [
        Text(
          'Tìm đồng đội. Lên sân.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Dữ liệu minh họa • Khoảng cách tương đối',
          style: AppTokens.label,
        ),
        if (controller.busy) const LinearProgressIndicator(),
        if (controller.error != null) ...[
          Text(controller.error!),
          TextButton(
            onPressed: controller.busy ? null : controller.load,
            child: const Text('Thử lại'),
          ),
        ],
        if (!controller.busy && controller.rooms.isEmpty)
          const Text('Chưa có kèo. Hãy tạo kèo đầu tiên.'),
        for (final room in controller.rooms)
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
                      controller.busy ||
                          room.availableSlots == 0 ||
                          room.playerIds.contains(
                            MatchController.currentPlayerId,
                          )
                      ? null
                      : () => controller.join(room.id),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    room.playerIds.contains(MatchController.currentPlayerId)
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
