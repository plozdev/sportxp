import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../profile/domain/player_profile.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({
    super.key,
    required this.players,
    required this.onRefresh,
  });
  final Future<List<PlayerProfile>> players;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => AsyncPanel<List<PlayerProfile>>(
    future: players,
    onRetry: onRefresh,
    builder: (items) => PageContent(
      children: [
        Text(
          'Xếp hạng phong trào',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Cập nhật bảng xếp hạng'),
          ),
        ),
        if (items.isEmpty)
          const BentoCard(
            child: Text('Chưa có vận động viên trong bảng xếp hạng.'),
          ),
        for (var i = 0; i < items.length; i++)
          BentoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    '${i + 1}',
                    style: AppTokens.metric.copyWith(
                      color: i < 3 ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(items[i].tierName, style: AppTokens.label),
                      const SizedBox(height: 12),
                      Text('${items[i].eloRating}', style: AppTokens.metric),
                      const Text('Elo', style: AppTokens.label),
                      const SizedBox(height: 8),
                      Text(
                        'Chuỗi ${items[i].winStreak} trận thắng',
                        style: AppTokens.label,
                      ),
                    ],
                  ),
                ),
                if (i < 3)
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
