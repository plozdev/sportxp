import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/player_profile.dart';

/// Pill thông minh hiển thị vị trí của người dùng khi họ lướt xa khỏi vị trí của mình
class SmartJumpPill extends StatelessWidget {
  const SmartJumpPill({
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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('smart_jump_pill_button'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(180),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF07080A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bạn: ${userProfile.displayName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${userProfile.eloRating ?? 750} Elo)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 11,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
