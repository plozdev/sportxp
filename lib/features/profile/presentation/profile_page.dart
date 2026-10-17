import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../domain/player_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.isSignedIn,
    required this.onSignIn,
    required this.onSignOut,
    required this.onRefresh,
  });
  final Future<PlayerProfile?> profile;
  final bool isSignedIn;
  final VoidCallback onSignIn, onSignOut, onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return PageContent(
        children: [
          Text(
            'Hộ chiếu cầu lông',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đăng nhập để xem Elo và thành tích của bạn.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onSignIn,
                  child: const Text('ĐĂNG NHẬP'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return AsyncPanel<PlayerProfile?>(
      future: profile,
      onRetry: onRefresh,
      builder: (player) => PageContent(
        children: [
          Text(
            'Hộ chiếu cầu lông',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (player == null)
            const BentoCard(
              child: Text(
                'Chưa có hồ sơ cho tài khoản này. Vui lòng kiểm tra cấu hình tạo hồ sơ khi đăng ký.',
              ),
            )
          else
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.displayName),
                  const SizedBox(height: 16),
                  Text(
                    player.eloRating?.toString() ?? '—',
                    style: AppTokens.metric,
                  ),
                  Text('Elo • ${player.tierName}', style: AppTokens.label),
                  const Divider(height: 32),
                  Text(
                    '★ ${player.trustScore} Uy tín   •   ${player.winStreak} trận thắng liên tiếp',
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Cập nhật hồ sơ'),
          ),
          TextButton(onPressed: onSignOut, child: const Text('Đăng xuất')),
        ],
      ),
    );
  }
}
