import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/rank_tier.dart';

class PodiumView extends StatelessWidget {
  const PodiumView({
    super.key,
    required this.topPlayers,
    required this.selectedPlayerId,
    required this.onTapPlayer,
  });

  final List<PlayerProfile> topPlayers;
  final String? selectedPlayerId;
  final ValueChanged<PlayerProfile> onTapPlayer;

  @override
  Widget build(BuildContext context) {
    if (topPlayers.isEmpty) return const SizedBox.shrink();

    final first = topPlayers.isNotEmpty ? topPlayers[0] : null;
    final second = topPlayers.length > 1 ? topPlayers[1] : null;
    final third = topPlayers.length > 2 ? topPlayers[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: Color(0xFFFFD700),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'BỤC VINH DANH TOP SÂN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFFFFD700).withAlpha(220),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Silver)
              Expanded(
                child: second != null
                    ? _buildPodiumStep(
                        player: second,
                        rank: 2,
                        pedestalHeight: 70,
                        medalColor: const Color(0xFFC0C0C0),
                        medalIcon: Icons.military_tech,
                        isUser: second.id == selectedPlayerId,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              // 1st Place (Gold)
              Expanded(
                child: first != null
                    ? _buildPodiumStep(
                        player: first,
                        rank: 1,
                        pedestalHeight: 95,
                        medalColor: const Color(0xFFFFD700),
                        medalIcon: Icons.emoji_events,
                        isUser: first.id == selectedPlayerId,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              // 3rd Place (Bronze)
              Expanded(
                child: third != null
                    ? _buildPodiumStep(
                        player: third,
                        rank: 3,
                        pedestalHeight: 52,
                        medalColor: const Color(0xFFCD7F32),
                        medalIcon: Icons.workspace_premium,
                        isUser: third.id == selectedPlayerId,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required PlayerProfile player,
    required int rank,
    required double pedestalHeight,
    required Color medalColor,
    required IconData medalIcon,
    required bool isUser,
  }) {
    final elo = player.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);

    return InkWell(
      onTap: () => onTapPlayer(player),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown or medal badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Avatar
              Container(
                width: rank == 1 ? 58 : 48,
                height: rank == 1 ? 58 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(
                    color: isUser ? AppColors.primary : medalColor,
                    width: isUser ? 2.5 : 2.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    player.initials,
                    style: TextStyle(
                      fontSize: rank == 1 ? 16 : 14,
                      fontWeight: FontWeight.w700,
                      color: isUser ? AppColors.primary : AppColors.text,
                    ),
                  ),
                ),
              ),
              // Position badge on top of avatar
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: medalColor.withAlpha(80),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    medalIcon,
                    size: rank == 1 ? 14 : 12,
                    color: const Color(0xFF07080A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            player.displayName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          // Tier
          Text(
            tier.label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          // Elo
          Text(
            '$elo',
            style: AppTokens.metric.copyWith(
              fontSize: 14,
              color: medalColor,
            ),
          ),
          const SizedBox(height: 8),
          // Pedestal Base
          Container(
            height: pedestalHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(
                color: isUser ? AppColors.primary : AppColors.border,
                width: isUser ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: rank == 1 ? 20 : 16,
                    fontWeight: FontWeight.w900,
                    color: medalColor,
                  ),
                ),
                if (player.winStreak > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 10,
                        color: AppColors.streak,
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
          ),
        ],
      ),
    );
  }
}
