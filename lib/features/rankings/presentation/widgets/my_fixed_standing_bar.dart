import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';
import '../../domain/leaderboard_repository.dart';

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
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SafeArea(
      top: false,
      child: InkWell(
        key: const Key('my_fixed_standing_row'),
        onTap: onScrollToMyRank,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                '#${rankSummary.rank}',
                style: AppTokens.metric.copyWith(
                  fontSize: 23,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${userProfile.displayName} · Bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      rankSummary.pointsToNextRank != null
                          ? 'Cách #${rankSummary.rank - 1}: ${rankSummary.pointsToNextRank} Elo'
                          : 'Vị trí dẫn đầu',
                      style: AppTokens.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                userProfile.eloRating?.toString() ?? '—',
                style: AppTokens.metric.copyWith(
                  fontSize: 21,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
