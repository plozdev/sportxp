import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/rank_tier.dart';

class DuolingoRankRow extends StatelessWidget {
  const DuolingoRankRow({
    super.key,
    required this.player,
    required this.rank,
    required this.isCurrentUser,
    required this.onTap,
  });

  final PlayerProfile player;
  final int rank;
  final bool isCurrentUser;
  final VoidCallback onTap;

  Color _getRankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return isCurrentUser ? AppColors.primary : const Color(0xFFB0B8C4);
  }

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
    final rankColor = _getRankColor();
    final elo = player.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);
    final tierColor = _getTierColor(tier);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withAlpha(24)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? AppColors.primary
                : (rank <= 3
                    ? rankColor.withAlpha(50)
                    : AppColors.border),
            width: isCurrentUser ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Rank Number / Medal
            SizedBox(
              width: 38,
              child: rank <= 3
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          rank == 1
                              ? Icons.emoji_events
                              : rank == 2
                              ? Icons.military_tech
                              : Icons.workspace_premium,
                          color: rankColor,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w700,
                        color: isCurrentUser ? AppColors.primary : const Color(0xFF9EA3AE),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 10),

            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(
                  color: isCurrentUser ? AppColors.primary : AppColors.border,
                  width: isCurrentUser ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  player.initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? AppColors.primary : AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Tier tag + Streak
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          player.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BẠN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF07080A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      // Tier badge rõ ràng, tương phản tốt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tierColor.withAlpha(120), width: 1.0),
                        ),
                        child: Text(
                          tier.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: tierColor,
                          ),
                        ),
                      ),
                      // Streak rõ ràng, rực lửa
                      if (player.winStreak > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.streak.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.streak,
                                size: 13,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${player.winStreak}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.streak,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Elo Score nổi bật
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$elo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isCurrentUser ? AppColors.primary : AppColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  'Elo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
