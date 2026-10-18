import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';

class StickyMyRankBar extends StatelessWidget {
  const StickyMyRankBar({
    super.key,
    required this.userProfile,
    required this.rank,
    required this.onTap,
  });

  final PlayerProfile userProfile;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(160),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                // Rank badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF07080A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                  child: Center(
                    child: Text(
                      userProfile.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userProfile.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
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
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${userProfile.eloRating ?? 750} Elo · ${userProfile.tierName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scroll button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đến vị trí',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_upward, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
