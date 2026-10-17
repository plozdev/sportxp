import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../rankings/domain/rank_tier.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      Text(
        'Hộ chiếu cầu lông',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vận động viên demo'),
            const SizedBox(height: 16),
            const Text('1,428', style: AppTokens.metric),
            Text(
              'Elo • ${RankTier.fromElo(1428).label}',
              style: AppTokens.label,
            ),
            const Divider(height: 32),
            const Text('★ 98 Uy tín   •   4 trận thắng liên tiếp'),
            const SizedBox(height: 12),
            const Text(
              'Các chỉ số trên là dữ liệu minh họa.',
              style: AppTokens.label,
            ),
          ],
        ),
      ),
      const Text(
        'Lịch sử đối đầu và biểu đồ Elo sẽ hiển thị khi có dữ liệu tài khoản.',
      ),
    ],
  );
}
