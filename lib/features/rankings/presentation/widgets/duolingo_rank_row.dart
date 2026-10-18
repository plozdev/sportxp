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
    return isCurrentUser ? AppColors.primary : AppColors.muted;
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
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withAlpha(22)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? AppColors.primary
                : (rank <= 3
                    ? rankColor.withAlpha(40)
                    : AppColors.border),
            width: isCurrentUser ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Rank Number / Medal
            SizedBox(
              width: 34,
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
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                        color: isCurrentUser ? AppColors.primary : AppColors.muted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 8),

            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background,
                border: Border.all(
                  color: isCurrentUser ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  player.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCurrentUser ? AppColors.primary : AppColors.text,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + Tier tag
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
                            fontSize: 13,
                            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BẠN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF07080A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: tierColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          tier.label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ),
                      if (player.winStreak > 0) ...[
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: AppColors.streak,
                              size: 11,
                            ),
                            Text(
                              '${player.winStreak}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
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

            // Elo Score
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$elo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isCurrentUser ? AppColors.primary : AppColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  'Elo',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
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
