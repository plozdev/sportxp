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
  });

  final ActivityView post;
  final String? caption;
  final ActivityAudience? audience;
  final List<Widget> actions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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

  @override
  Widget build(BuildContext context) {
    final stats = post.totals;
    final currentAudience = audience ?? post.audience;
    final currentCaption = caption ?? post.caption;
    final isPersonal = post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. NGƯỜI ĐĂNG (Avatar, Tên, Badge, Thời gian & Menu ⋯)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar tròn vận động viên
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                  border: Border.all(
                    color: isPersonal ? AppColors.primary : AppColors.streak,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(post.authorName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isPersonal ? AppColors.primary : AppColors.streak,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                        const SizedBox(width: 6),
                        // Badge: Cá nhân / Host
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isPersonal
                                    ? AppColors.primary
                                    : AppColors.streak)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPersonal ? 'Cá nhân' : 'Host tổng kết',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPersonal
                                  ? AppColors.primary
                                  : AppColors.streak,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          currentAudience == ActivityAudience.friends
                              ? Icons.people_alt_outlined
                              : Icons.lock_outline,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentAudience == ActivityAudience.friends
                              ? 'Bạn bè'
                              : 'Chỉ mình tôi',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                        if (post.publishedAt != null) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.muted)),
                          Text(
                            _formatTime(post.publishedAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ] else if (post.isDraft) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.muted)),
                          const Text(
                            'BẢN NHÁP · chưa chia sẻ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.streak,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Menu ⋯ thu gọn các thao tác quản trị (Sửa / Xóa) & Chia sẻ
              if (post.isOwner && (onEdit != null || onDelete != null))
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  tooltip: 'Tùy chọn bài viết',
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
                          Text('Chia sẻ hoạt động'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 10),
                          Text('Sửa bài'),
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

          // 2. CAPTION (Tự nhiên như bài đăng bạn bè, không đóng khung hộp dashboard)
          if (currentCaption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              currentCaption,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 3. TIÊU ĐỀ BUỔI CHƠI & ĐỊA ĐIỂM SÂN (Chỉ nhắc 1 lần rõ ràng)
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${post.courtName} • ${_formatTime(post.playedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 4. HÌNH SÂN / TỔNG KẾT TRẬN (Graphic thể thao trung tâm duy nhất)
          BadmintonCourtGraphic(post: post, height: 130),

          const SizedBox(height: 10),

          // 5. TRẠNG THÁI XÁC NHẬN (Giải thích rõ ràng bằng tiếng Việt, tránh hiểu nhầm)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  stats.pending > 0
                      ? Icons.hourglass_top_rounded
                      : (stats.disputed > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline),
                  size: 16,
                  color: stats.pending > 0
                      ? AppColors.streak
                      : (stats.disputed > 0
                          ? AppColors.loss
                          : AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPersonal
                            ? '$wins thắng · $losses thua đã xác nhận'
                            : '${stats.confirmed}/${stats.total} trận đã xác nhận',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (stats.pending > 0)
                        Text(
                          'Còn ${stats.pending} trận chờ đối thủ hoặc host chốt',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.streak,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (stats.disputed > 0)
                        const Text(
                          'Có trận đang trong trạng thái tranh chấp tỷ số',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.loss,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const Text(
                          'Toàn bộ kết quả trong buổi đã được chốt',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badges cập nhật kết quả muộn hoặc hủy
          if (post.resultsUpdated) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync, size: 13, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Kết quả đã cập nhật sau khi xác nhận trận',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (stats.voided > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${stats.voided} bản ghi đã hủy, không tính thành tích',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],

          // 6. SOCIAL REACTIONS BAR (Kudos, Chi tiết, Chia sẻ)
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}
