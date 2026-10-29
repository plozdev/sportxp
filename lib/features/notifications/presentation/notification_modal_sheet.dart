import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/notice_repository.dart';
import '../domain/sport_notice.dart';

class NotificationModalSheet extends StatefulWidget {
  const NotificationModalSheet({
    super.key,
    required this.repository,
    required this.onNoticesUpdated,
  });

  final NoticeRepository repository;
  final VoidCallback onNoticesUpdated;

  static Future<void> show(
    BuildContext context,
    NoticeRepository repository, {
    required VoidCallback onNoticesUpdated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NotificationModalSheet(
        repository: repository,
        onNoticesUpdated: onNoticesUpdated,
      ),
    );
  }

  @override
  State<NotificationModalSheet> createState() => _NotificationModalSheetState();
}

class _NotificationModalSheetState extends State<NotificationModalSheet> {
  List<SportNotice> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final data = await widget.repository.listNotices();
    if (mounted) {
      setState(() {
        _notices = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(SportNotice notice) async {
    await widget.repository.markAsRead(notice.id);
    widget.onNoticesUpdated();
    _fetch();
  }

  Future<void> _markAllRead() async {
    await widget.repository.markAllAsRead();
    widget.onNoticesUpdated();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'THÔNG BÁO CỦA BẠN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_notices.any((n) => !n.isRead))
                TextButton(
                  onPressed: _markAllRead,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Đã đọc tất cả', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : _notices.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 36, color: AppColors.muted),
                        SizedBox(height: 8),
                        Text(
                          'Không có thông báo mới',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _notices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notices[index];
                      return _NoticeTile(
                        notice: item,
                        onTap: () => _markRead(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.onTap,
  });

  final SportNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notice.isRead ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notice.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.35),
            width: notice.isRead ? 1 : 1.3,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notice.isRead ? Colors.transparent : AppColors.loss,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: notice.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notice.content,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notice.createdAt),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 60)} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
