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
    if (minutes == null || minutes <= 0) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
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
                      isPersonal ? AppColors.accent : AppColors.streak,
                      AppColors.primary,
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
                    Text(
                      '${_sportLabel(sportType)} · $timeStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if (post.courtName.isNotEmpty)
                      Text(
                        post.courtName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),

              // Huy hiệu trạng thái / Menu
              if (currentAudience == ActivityAudience.onlyMe)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 11,
                        color: AppColors.muted,
                      ),
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
                          Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.loss,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Xóa bài',
                            style: TextStyle(color: AppColors.loss),
                          ),
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
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.2,
              ),
            ),

          if (currentCaption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              currentCaption,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
          ],

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = <Widget>[
                if (sportType == 'running') ...[
                  _MetricCol(
                    label: 'Quãng đường',
                    value: post.distanceKm?.toStringAsFixed(2) ?? '—',
                    unit: 'km',
                    highlight: true,
                  ),
                  _MetricCol(
                    label: 'Pace trung bình',
                    value: post.pace ?? '—',
                    unit: '/km',
                  ),
                ] else if (sportType == 'workout') ...[
                  _MetricCol(
                    label: 'Thời gian',
                    value: _formatDuration(post.durationMinutes),
                  ),
                  _MetricCol(
                    label: 'Tiêu hao',
                    value: post.calories?.toString() ?? '—',
                    unit: 'kcal',
                    highlight: true,
                  ),
                ] else ...[
                  _MetricCol(
                    label: isPersonal ? 'Thắng – thua' : 'Trận xác nhận',
                    value: isPersonal
                        ? '$wins – $losses'
                        : '${stats.confirmed}/${stats.total}',
                    highlight: true,
                  ),
                  _MetricCol(
                    label: 'Thời gian',
                    value: _formatDuration(post.durationMinutes),
                  ),
                ],
              ];
              return Wrap(
                spacing: 16,
                runSpacing: 14,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: constraints.maxWidth < 270
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2,
                      child: metric,
                    ),
                ],
              );
            },
          ),
          if (stats.pending > 0 || post.resultsUpdated) ...[
            const SizedBox(height: 12),
            Text(
              post.resultsUpdated
                  ? 'Kết quả đã được cập nhật'
                  : '${stats.pending} trận đang chờ xác nhận',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AthleticVisualGraphic(post: post, height: 190),
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
                Flexible(
                  child: Text(
                    'Thiết bị mẫu · ${post.deviceSource}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
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
            Wrap(alignment: WrapAlignment.spaceBetween, children: actions),
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
    final remaining = post.likeCount > names.length
        ? post.likeCount - 2
        : names.length - 2;
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
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
                  color: AppColors.primary,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    displayNames[i].isNotEmpty ? displayNames[i][0] : '?',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
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
