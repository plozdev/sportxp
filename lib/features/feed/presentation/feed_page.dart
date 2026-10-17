import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});
  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      Text(
        'Mọi set cầu đều được\nđịnh danh và ghi nhận.',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const Text('THẺ TRẬN ĐẤU MẪU', style: AppTokens.label),
      BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BẠN & MINH  /  LINH & NAM', style: AppTokens.label),
            const SizedBox(height: 16),
            const Text('21–19   21–16', style: AppTokens.metric),
            const SizedBox(height: 16),
            Text(
              '+18 ELO',
              style: AppTokens.metric.copyWith(color: AppColors.primary),
            ),
            const Text(
              'Sân Đào Duy Anh • Kết quả minh họa',
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
  );
}
