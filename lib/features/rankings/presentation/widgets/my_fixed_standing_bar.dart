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
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header title của fixed bar: Tên sân + Khoảng cách đối thủ liền kề (an toàn chống tràn)
              Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'VỊ TRÍ CỦA BẠN TẠI ${rankSummary.courtName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rankSummary.pointsToNextRank != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Cách #${rankSummary.rank - 1}: ${rankSummary.pointsToNextRank} Elo',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Nội dung hàng của bạn
              InkWell(
                key: const Key('my_fixed_standing_row'),
                onTap: onScrollToMyRank,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
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
                      // Badge Rank + Movement delta
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${rankSummary.rank}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF07080A),
                              ),
                            ),
                            if (rankSummary.rankDelta != 0) ...[
                              const SizedBox(width: 2),
                              Icon(
                                rankSummary.rankDelta > 0
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                size: 14,
                                color: const Color(0xFF07080A),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Center(
                          child: Text(
                            userProfile.initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tên & Tier
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: userProfile.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                                children: const [
                                  TextSpan(
                                    text: ' (Bạn)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tierColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    tier.label,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: tierColor,
                                    ),
                                  ),
                                ),
                                if (userProfile.winStreak > 0) ...[
                                  const SizedBox(width: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 11,
                                        color: AppColors.streak,
                                      ),
                                      Text(
                                        '${userProfile.winStreak}',
                                        style: const TextStyle(
                                          fontSize: 10,
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

                      const SizedBox(width: 6),

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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Text(
                                'Elo',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
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
                              SizedBox(width: 1),
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
