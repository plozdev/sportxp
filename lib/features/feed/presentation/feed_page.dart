import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../domain/match_summary.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
    required this.matches,
    required this.onRecord,
    required this.onRefresh,
  });
  final Future<List<MatchSummary>> matches;
  final VoidCallback onRecord, onRefresh;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.add),
                label: const Text('Ghi nhận set cầu'),
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Cập nhật bảng tin',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      Expanded(
        child: AsyncPanel<List<MatchSummary>>(
          future: matches,
          onRetry: onRefresh,
          builder: (items) => PageContent(
            children: [
              Text(
                'Mọi set cầu đều được\nđịnh danh và ghi nhận.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (items.isEmpty)
                const BentoCard(
                  child: Text(
                    'Chưa có trận đấu. Ghi nhận set cầu đầu tiên của bạn.',
                  ),
                ),
              for (final match in items)
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${match.teamA}  /  ${match.teamB}',
                        style: AppTokens.label,
                      ),
                      const SizedBox(height: 16),
                      Text(match.score, style: AppTokens.metric),
                      const SizedBox(height: 16),
                      Text(
                        match.isWin ? 'ĐỘI A THẮNG' : 'ĐỘI B THẮNG',
                        style: TextStyle(
                          color: match.isWin
                              ? AppColors.primary
                              : AppColors.loss,
                        ),
                      ),
                      if (match.eloChange != null)
                        Text(
                          '${match.eloChange! >= 0 ? '+' : ''}${match.eloChange} ELO',
                          style: AppTokens.metric.copyWith(
                            color: match.eloChange! >= 0
                                ? AppColors.primary
                                : AppColors.loss,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${match.courtName} • ${match.createdAt.day}/${match.createdAt.month}/${match.createdAt.year}',
                        style: AppTokens.label,
                      ),
                    ],
                  ),
                ),
              const BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_border, color: AppColors.muted),
                    SizedBox(height: 12),
                    Text('Sức khỏe chưa kết nối'),
                    SizedBox(height: 8),
                    Text(
                      'HealthKit / Health Connect sẽ được tích hợp sau. Chỉ đọc dữ liệu khi bạn cấp quyền.',
                      style: AppTokens.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
