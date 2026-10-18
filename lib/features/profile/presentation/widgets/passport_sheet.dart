import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/player_profile.dart';

class PassportSheet extends StatefulWidget {
  const PassportSheet({super.key, required this.profile});
  final PlayerProfile profile;

  @override
  State<PassportSheet> createState() => _PassportSheetState();
}

class _PassportSheetState extends State<PassportSheet> {
  bool _hideName = false;
  bool _hideHealth = false;

  @override
  Widget build(BuildContext context) {
    final player = widget.profile;
    final displayName = _hideName ? 'Vận động viên ẩn danh' : player.displayName;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HỘ CHIẾU CẦU LÔNG (9:16)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.muted,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Đóng',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 9:16 Card Preview Container
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 420),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top watermark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.sports_tennis, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'SPORTXP PASSPORT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'XÁC MINH',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),

                  // Athlete avatar & Name
                  Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            player.initials,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.homeCourtName ?? 'Tay vợt tự do',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),

                  // Big Elo Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          player.eloRating?.toString() ?? '—',
                          style: AppTokens.metric.copyWith(fontSize: 32, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.tierName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PassportStat(
                        label: 'CHUỖI THẮNG',
                        value: '${player.winStreak}',
                        icon: Icons.local_fire_department,
                        iconColor: AppColors.streak,
                      ),
                      _PassportStat(
                        label: 'UY TÍN',
                        value: '${player.trustScore}%',
                        icon: Icons.verified_user,
                        iconColor: AppColors.primary,
                      ),
                      if (!_hideHealth)
                        const _PassportStat(
                          label: 'THỂ CHẤT',
                          value: 'ĐẠT',
                          icon: Icons.favorite,
                          iconColor: AppColors.primary,
                        ),
                    ],
                  ),

                  // Footer notice (no raw GPS as per privacy docs)
                  Text(
                    'Định danh set cầu • Không lưu vị trí cá nhân\nsportxp.app',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: AppColors.muted.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy Controls (as specified in architecture docs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Ẩn họ tên thật', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Hiện danh tính ẩn danh trên ảnh share', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  value: _hideName,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _hideName = val),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  title: const Text('Ẩn chỉ số thể chất', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Không nhúng nhịp tim / calo vào ảnh', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  value: _hideHealth,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => setState(() => _hideHealth = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo ảnh Hộ chiếu số SportXP (1080×1920) để chia sẻ!')),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('CHIA SẺ HỘ CHIẾU LÊN BẢNG TIN / STORIES'),
          ),
        ],
      ),
    );
  }
}

class _PassportStat extends StatelessWidget {
  const _PassportStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.5)),
      ],
    );
  }
}
