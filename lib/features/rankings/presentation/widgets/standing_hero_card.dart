import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/rank_tier.dart';

class StandingHeroCard extends StatelessWidget {
  const StandingHeroCard({
    super.key,
    required this.rankSummary,
    required this.userProfile,
    required this.onJumpToMyRank,
  });

  final PlayerCourtRank rankSummary;
  final PlayerProfile userProfile;
  final VoidCallback onJumpToMyRank;

  Color _getTierColor(RankTier tier) {
    switch (tier.group) {
      case RankGroup.newbie:
      case RankGroup.weak:
        return const Color(0xFF94A3B8); // Slate
      case RankGroup.lowerIntermediate:
      case RankGroup.intermediate:
        return const Color(0xFFF59E0B); // Amber / Bronze
      case RankGroup.upperIntermediate:
        return const Color(0xFF60A5FA); // Sky / Silver
      case RankGroup.advanced:
        return const Color(0xFFA855F7); // Purple / Gold
      case RankGroup.strong:
        return const Color(0xFFEC4899); // Pink / Platinum
      case RankGroup.eliteAmateur:
        return AppColors.primary; // Court Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final elo = userProfile.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);
    final tierColor = _getTierColor(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: rankSummary.isPodium
              ? AppColors.primary.withAlpha(80)
              : AppColors.border,
          width: rankSummary.isPodium ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VỊ THẾ TẠI ${rankSummary.courtName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onJumpToMyRank,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem vị trí',
                        style: TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_downward, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Rank badge lớn
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: rankSummary.isPodium
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'HẠNG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        '#${rankSummary.rank}',
                        style: AppTokens.metric.copyWith(
                          fontSize: 24,
                          color: rankSummary.isPodium
                              ? AppColors.primary
                              : AppColors.text,
                        ),
                      ),
                    ],
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
                            userProfile.displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tierColor.withAlpha(100)),
                          ),
                          child: Text(
                            tier.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$elo',
                          style: AppTokens.metric.copyWith(
                            fontSize: 20,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Elo', style: AppTokens.label),
                        const SizedBox(width: 12),
                        Text(
                          '/ ${rankSummary.totalPlayers} tay vợt',
                          style: AppTokens.label,
                        ),
                      ],
                    ),
                    if (userProfile.winStreak > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AppColors.streak,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Chuỗi ${userProfile.winStreak} trận thắng',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.streak,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Duolingo motivation banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  rankSummary.rank == 1
                      ? Icons.emoji_events
                      : rankSummary.isPodium
                      ? Icons.workspace_premium
                      : Icons.trending_up,
                  size: 18,
                  color: rankSummary.isPodium
                      ? const Color(0xFFFFD700)
                      : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildMotivationText(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMotivationText() {
    if (rankSummary.rank == 1) {
      return 'Vua sân! Bạn đang giữ vị trí số 1 tại sân này.';
    }
    if (rankSummary.isPodium) {
      return 'Vinh danh Top ${rankSummary.rank}! Bạn đang trong nhóm hạt giống.';
    }
    if (rankSummary.pointsToNextRank != null &&
        rankSummary.nextPlayerName != null) {
      return 'Cần +${rankSummary.pointsToNextRank} Elo nữa để vượt qua ${rankSummary.nextPlayerName}!';
    }
    return 'Thi đấu thêm trận để thăng hạng trong sân!';
  }
}
