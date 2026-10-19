import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';
import 'badminton_court_canvas.dart';

/// Modal chia sẻ bài đăng hoạt động đậm chất Strava Story / Social Card
class ActivityShareSheet extends StatelessWidget {
  const ActivityShareSheet({
    super.key,
    required this.post,
  });

  final ActivityView post;

  static Future<void> show(BuildContext context, ActivityView post) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ActivityShareSheet(post: post),
      );

  @override
  Widget build(BuildContext context) {
    final stats = post.totals;
    final isPersonal = post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chia sẻ thành tích',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'Khoe khoảnh khắc thể thao với bạn bè',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Strava-style Athletic Share Card Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: App branding & Sport tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sports_tennis_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SPORTXP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        isPersonal ? 'CÁ NHÂN' : 'HOST BUỔI CHƠI',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Graphic athletic visual
                AthleticVisualGraphic(post: post, height: 120),

                const SizedBox(height: 12),

                // Title & Court
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.authorName} • ${post.courtName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),

                if (post.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '"${post.caption}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Athletic Metrics Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (post.sportType == 'running') ...[
                        _ShareMetric(
                          label: 'QUÃNG ĐƯỜNG',
                          value: '${post.distanceKm != null ? post.distanceKm!.toStringAsFixed(2) : "5.20"} km',
                        ),
                        _ShareMetric(
                          label: 'PACE',
                          value: '${post.pace ?? "5:26"} /km',
                        ),
                        _ShareMetric(
                          label: 'THỜI GIAN',
                          value: '${post.durationMinutes ?? 28}m',
                        ),
                      ] else if (post.sportType == 'workout') ...[
                        _ShareMetric(
                          label: 'THỜI GIAN',
                          value: '${post.durationMinutes ?? 45}m',
                        ),
                        _ShareMetric(
                          label: 'TIÊU HAO',
                          value: '${post.calories ?? 410} kcal',
                        ),
                        _ShareMetric(
                          label: 'NHỊP TIM',
                          value: '${post.avgHeartRate ?? 140} bpm',
                        ),
                      ] else ...[
                        _ShareMetric(
                          label: 'THỜI GIAN',
                          value: '${post.durationMinutes ?? 75}m',
                        ),
                        _ShareMetric(
                          label: 'TIÊU HAO',
                          value: '${post.calories ?? 480} kcal',
                        ),
                        _ShareMetric(
                          label: isPersonal ? 'KẾT QUẢ' : 'TỔNG SET',
                          value: isPersonal
                              ? '${wins}W - ${losses}L'
                              : '${stats.confirmed}/${stats.total}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Share Actions Grid
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            'Cùng xem thành tích cầu lông của ${post.authorName} tại ${post.courtName}: ${isPersonal ? '${wins}W - ${losses}L' : '${stats.total} set'}. Xem tại SportXP!',
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép liên kết hoạt động!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Sao chép link'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã lưu ảnh khoảnh khắc thể thao!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Lưu ảnh Story',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareMetric extends StatelessWidget {
  const _ShareMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

