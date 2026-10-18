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
  });

  final ActivityView post;
  final String? caption;
  final ActivityAudience? audience;
  final List<Widget> actions;

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

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ATHLETE HEADER (Avatar, Tên, Badge cá nhân/host, Quyền riêng tư & Nút chia sẻ)
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
              // Nút chia sẻ nhanh ở Header
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

          // 2. ACTIVITY TITLE & VENUE (Tiêu đề buổi chơi & Địa điểm sân cầu)
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
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

          const SizedBox(height: 12),

          // 3. STRAVA-STYLE ATHLETIC COURT GRAPHIC (Visual Map của buổi cầu lông)
          BadmintonCourtGraphic(post: post, height: 135),

          // 4. CAPTION / ATHLETE THOUGHT (Cảm nhận buổi chơi)
          if (currentCaption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3.5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(9),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          currentCaption,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.text,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 5. STRAVA-STYLE ATHLETIC STATS DASHBOARD (Bảng chỉ số buổi chơi)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Cột 1: Chiến tích Thắng / Thua hoặc Trận chốt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPersonal
                            ? '${stats.wins ?? 0}W - ${stats.losses ?? 0}L'
                            : '${stats.confirmed} chốt',
                        style: AppTokens.metric.copyWith(
                          fontSize: 20,
                          color: (stats.wins ?? 0) >= (stats.losses ?? 0)
                              ? AppColors.primary
                              : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPersonal ? 'Thành tích xác nhận' : 'Trận đã chốt',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Cột 2: Tổng số trận trong buổi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stats.total}',
                        style: AppTokens.metric.copyWith(
                          fontSize: 20,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tổng số trận',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Cột 3: Trạng thái chốt / chờ xác nhận
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            stats.pending > 0
                                ? Icons.hourglass_top_rounded
                                : (stats.disputed > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline),
                            size: 15,
                            color: stats.pending > 0
                                ? AppColors.streak
                                : (stats.disputed > 0
                                    ? AppColors.loss
                                    : AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stats.pending > 0
                                  ? 'Chờ ${stats.pending}'
                                  : (stats.disputed > 0
                                      ? 'Tranh chấp'
                                      : 'Đã chốt'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: stats.pending > 0
                                    ? AppColors.streak
                                    : (stats.disputed > 0
                                        ? AppColors.loss
                                        : AppColors.primary),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats.confirmed == stats.total
                            ? '100% hoàn tất'
                            : '${stats.confirmed}/${stats.total} trận chốt',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badges cảnh báo / Cập nhật kết quả
          if (post.resultsUpdated) ...[
            const SizedBox(height: 8),
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

          const SizedBox(height: 8),
          const Text(
            'Elo: chưa tính · Không chia sẻ điểm danh hoặc lý do tranh chấp',
            style: TextStyle(fontSize: 10, color: AppColors.muted),
          ),

          // 6. SOCIAL ACTIONS BAR (Kudos, Chi tiết & Tùy chọn)
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
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
