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
    this.showDivider = true,
  });

  final PlayerProfile player;
  final int rank;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final bool showDivider;

  Color _getRankColor() {
    if (rank == 1) return const Color(0xFFF59E0B);
    if (rank == 2) return const Color(0xFF94A3B8);
    if (rank == 3) return const Color(0xFFD97706);
    return isCurrentUser ? AppColors.primary : const Color(0xFF64748B);
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

  Widget _buildRankDelta(int delta) {
    if (delta > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_up, size: 13, color: Color(0xFF10B981)),
          Text(
            '$delta',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      );
    } else if (delta < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_down, size: 13, color: Color(0xFFEF4444)),
          Text(
            '${delta.abs()}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      );
    } else {
      return const Text(
        '–',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      );
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppColors.primary.withAlpha(22)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isCurrentUser ? AppColors.primary : Colors.transparent,
              width: 3.5,
            ),
            bottom: showDivider
                ? BorderSide(
                    color: AppColors.border.withAlpha(45),
                    width: 0.8,
                  )
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Rank Number & Movement Delta
            SizedBox(
              width: 44,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: rank <= 3 || isCurrentUser
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: rankColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 1),
                  _buildRankDelta(player.rankDelta),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Avatar
            Container(
              width: 36,
              height: 36,
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
                    fontSize: 13,
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
                            fontSize: 14,
                            fontWeight: isCurrentUser
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BẠN',
                            style: TextStyle(
                              fontSize: 9,
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
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          tier.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ),
                      if (player.winStreak > 0) ...[
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: AppColors.streak,
                              size: 12,
                            ),
                            Text(
                              '${player.winStreak}',
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
                    fontWeight: FontWeight.w600,
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
