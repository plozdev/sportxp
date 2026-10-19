import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../domain/activity.dart';
import 'widgets/activity_share_sheet.dart';
import 'widgets/badminton_court_canvas.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.post,
    this.caption,
    this.audience,
    this.actions = const [],
    this.onEdit,
    this.onDelete,
    this.onLike,
    this.onComment,
    this.onTapDetail,
  });

  final ActivityView post;
  final String? caption;
  final ActivityAudience? audience;
  final List<Widget> actions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onTapDetail;

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'XP';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '45m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  IconData _sportIcon(String? sportType) {
    switch (sportType) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'badminton':
      default:
        return Icons.sports_tennis_rounded;
    }
  }

  String _sportLabel(String? sportType) {
    switch (sportType) {
      case 'running':
        return 'Chạy bộ';
      case 'workout':
        return 'Tập bổ trợ';
      case 'badminton':
      default:
        return 'Cầu lông';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = post.totals;
    final currentAudience = audience ?? post.audience;
    final currentCaption = caption ?? post.caption;
    final isPersonal = post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;
    final timeStr = _formatTime(post.publishedAt ?? post.playedAt);
    final sportType = post.sportType;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. STRAVA HEADER: 2 DÒNG RÕ RÀNG, KHÔNG BỊ TRUNCATION
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar tròn thể thao
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isPersonal ? AppColors.primary : AppColors.streak,
                      const Color(0xFF1E293B),
                    ],
                  ),
                  border: Border.all(
                    color: isPersonal
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.streak.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(post.authorName),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Dòng 1: Tên Vận Động Viên
              // Dòng 2: Môn · Thời gian · Sân bãi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.authorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Bạn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _sportIcon(sportType),
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _sportLabel(sportType),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        if (post.courtName.isNotEmpty) ...[
                          const Text(
                            ' · ',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          Flexible(
                            child: Text(
                              post.courtName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Huy hiệu trạng thái / Menu
              if (currentAudience == ActivityAudience.onlyMe)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 11, color: AppColors.muted),
                      SizedBox(width: 3),
                      Text(
                        'Chỉ mình tôi',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),

              if (post.isOwner && (onEdit != null || onDelete != null))
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  tooltip: 'Tùy chọn',
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  onSelected: (value) {
                    if (value == 'share') {
                      ActivityShareSheet.show(context, post);
                    } else if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 16),
                          SizedBox(width: 10),
                          Text('Chia sẻ thẻ ảnh'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 10),
                          Text('Sửa caption'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: AppColors.loss),
                          SizedBox(width: 10),
                          Text('Xóa bài', style: TextStyle(color: AppColors.loss)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () => ActivityShareSheet.show(context, post),
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  tooltip: 'Chia sẻ hoạt động',
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. TIÊU ĐỀ HOẠT ĐỘNG VÀ CAPTION CHÂN THẬT
          if (post.title.isNotEmpty)
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.2,
              ),
            ),

          if (currentCaption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“$currentCaption”',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD1D5DB), // Light grey text
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. KHỐI THÔNG SỐ THỂ CHẤT ĐẬM CHẤT STRAVA (ATHLETIC METRICS BOX)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sportType == 'running') ...[
                  _MetricCol(
                    label: 'QUÃNG ĐƯỜNG',
                    value: post.distanceKm != null
                        ? post.distanceKm!.toStringAsFixed(2)
                        : '5.20',
                    unit: 'km',
                    highlight: true,
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'PACE TB',
                    value: post.pace ?? '5:26',
                    unit: '/km',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'THỜI GIAN',
                    value: '${post.durationMinutes ?? 28}:15',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'TIÊU HAO',
                    value: '${post.calories ?? 365}',
                    unit: 'kcal',
                  ),
                ] else if (sportType == 'workout') ...[
                  _MetricCol(
                    label: 'THỜI GIAN',
                    value: '${post.durationMinutes ?? 45}',
                    unit: 'phút',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'TIÊU HAO',
                    value: '${post.calories ?? 410}',
                    unit: 'kcal',
                    highlight: true,
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'NHỊP TIM TB',
                    value: '${post.avgHeartRate ?? 140}',
                    unit: 'bpm',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'CỰC ĐẠI',
                    value: '${post.maxHeartRate ?? 165}',
                    unit: 'bpm',
                  ),
                ] else ...[
                  // Badminton stats
                  _MetricCol(
                    label: 'THỜI GIAN',
                    value: _formatDuration(post.durationMinutes),
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'TIÊU HAO',
                    value: '${post.calories ?? 520}',
                    unit: 'kcal',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: 'NHỊP TIM TB',
                    value: '${post.avgHeartRate ?? 146}',
                    unit: 'bpm',
                  ),
                  _MetricDivider(),
                  _MetricCol(
                    label: isPersonal ? 'KẾT QUẢ' : 'TỔNG SET',
                    value: isPersonal
                        ? '${wins}W - ${losses}L'
                        : '${stats.confirmed}/${stats.total}',
                    highlight: isPersonal && wins >= losses && wins > 0,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 4. HÌNH THỂ THAO TRỰC QUAN (Sân chiến thuật, GPS Route, hoặc Wave cường độ)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AthleticVisualGraphic(post: post, height: 120),
          ),

          // 5. THÔNG TIN ĐỒNG BỘ THIẾT BỊ (Apple Watch / Garmin / Strava Sync)
          if (post.deviceSource != null && post.deviceSource!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.watch_rounded,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Đồng bộ từ ${post.deviceSource}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],

          // 6. KUDOS FEEDBACK BAR (Ảnh bạn bè + số lượng)
          if (post.likeCount > 0 || post.likedByNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                // Overlapping avatar icons
                _KudosAvatarStack(names: post.likedByNames),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatKudosText(post),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.commentCount > 0)
                  Text(
                    '${post.commentCount} bình luận',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ],

          // 7. SOCIAL ACTIONS: Thích · Chi tiết · Chia sẻ
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }

  String _formatKudosText(ActivityView post) {
    final names = post.likedByNames;
    if (names.isEmpty) {
      return '${post.likeCount} người đã thả kudos';
    }
    if (names.length == 1) {
      return '${names[0]} đã thả kudos';
    }
    if (names.length == 2) {
      return '${names[0]} và ${names[1]} đã thả kudos';
    }
    final remaining = post.likeCount > names.length ? post.likeCount - 2 : names.length - 2;
    return '${names[0]}, ${names[1]} và $remaining người khác đã thả kudos';
  }
}

/// Widget hiển thị một cột thông số Strava
class _MetricCol extends StatelessWidget {
  const _MetricCol({
    required this.label,
    required this.value,
    this.unit,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String? unit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: highlight ? AppColors.primary : AppColors.text,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2.5),
              Text(
                unit!,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.border.withValues(alpha: 0.6),
    );
  }
}

/// Stack avatar tròn nhỏ chồng lên nhau của những người đã thả kudos
class _KudosAvatarStack extends StatelessWidget {
  const _KudosAvatarStack({required this.names});
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final displayNames = names.take(3).toList();
    if (displayNames.isEmpty) {
      return const Icon(
        Icons.favorite_rounded,
        size: 14,
        color: Color(0xFFFC5200),
      );
    }

    return SizedBox(
      width: 16.0 + (displayNames.length - 1) * 12.0,
      height: 20,
      child: Stack(
        children: [
          for (int i = 0; i < displayNames.length; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    displayNames[i].isNotEmpty ? displayNames[i][0] : '?',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
