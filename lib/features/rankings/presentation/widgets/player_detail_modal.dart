import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/rank_tier.dart';

class PlayerDetailModal extends StatelessWidget {
  const PlayerDetailModal({
    super.key,
    required this.player,
    required this.rank,
    this.isCurrentUser = false,
  });

  final PlayerProfile player;
  final int rank;
  final bool isCurrentUser;

  static void show(
    BuildContext context, {
    required PlayerProfile player,
    required int rank,
    bool isCurrentUser = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radius)),
      ),
      builder: (_) => PlayerDetailModal(
        player: player,
        rank: rank,
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elo = player.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(
                      color: isCurrentUser ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player.initials,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isCurrentUser ? AppColors.primary : AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              player.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BẠN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF07080A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hạng #$rank · ${tier.label} (${tier.group.label})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Metrics Row
            Row(
              children: [
                _buildStatBox(
                  label: 'ĐIỂM ELO',
                  value: '$elo',
                  color: AppColors.text,
                ),
                const SizedBox(width: 12),
                _buildStatBox(
                  label: 'CHUỖI THẮNG',
                  value: '${player.winStreak} 🔥',
                  color: AppColors.streak,
                ),
                const SizedBox(width: 12),
                _buildStatBox(
                  label: 'UY TÍN',
                  value: '${player.trustScore}%',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Home Court Info
            if (player.homeCourtName != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stadium_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sân hoạt động chính:',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        player.homeCourtName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Action button
            if (!isCurrentUser)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã gửi tín hiệu giao lưu tới ${player.displayName}!',
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Mời giao lưu / Thách đấu'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTokens.metric.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
