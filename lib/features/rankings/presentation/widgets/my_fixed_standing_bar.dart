import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/leaderboard_repository.dart';
import '../../domain/rank_tier.dart';

/// Hàng cố định hiển thị vị trí của người dùng trong sân, có vùng riêng biệt ở đáy không che danh sách
class MyFixedStandingBar extends StatelessWidget {
  const MyFixedStandingBar({
    super.key,
    required this.userProfile,
    required this.rankSummary,
    required this.onScrollToMyRank,
  });

  final PlayerProfile userProfile;
  final PlayerCourtRank rankSummary;
  final VoidCallback onScrollToMyRank;

  Color _getTierColor(RankTier tier) {
    switch (tier.group) {
      case RankGroup.newbie:
      case RankGroup.weak:
        return const Color(0xFF94A3B8);
      case RankGroup.lowerIntermediate:
      case RankGroup.intermediate:
        return const Color(0xFFF59E0B);
      case RankGroup.upperIntermediate:
        return const Color(0xFF60A5FA);
      case RankGroup.advanced:
        return const Color(0xFFA855F7);
      case RankGroup.strong:
        return const Color(0xFFEC4899);
      case RankGroup.eliteAmateur:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final elo = userProfile.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);
    final tierColor = _getTierColor(tier);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header title của fixed bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'VỊ TRÍ CỦA BẠN TẠI ${rankSummary.courtName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (rankSummary.pointsToNextRank != null &&
                      rankSummary.nextPlayerName != null) ...[
                    Text(
                      '+${rankSummary.pointsToNextRank} Elo để lên #${rankSummary.rank - 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Nội dung hàng của bạn
              InkWell(
                key: const Key('my_fixed_standing_row'),
                onTap: onScrollToMyRank,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(120),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Badge Rank
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${rankSummary.rank}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF07080A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Avatar
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Center(
                          child: Text(
                            userProfile.initials,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Tên & Tier
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userProfile.displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '(Bạn)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tierColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    tier.label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: tierColor,
                                    ),
                                  ),
                                ),
                                if (userProfile.winStreak > 0) ...[
                                  const SizedBox(width: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 12,
                                        color: AppColors.streak,
                                      ),
                                      Text(
                                        '${userProfile.winStreak}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.streak,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Elo & Nút cuộn
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$elo',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'Elo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Đến vị trí',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_upward,
                                size: 10,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
