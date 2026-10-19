import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/activity.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../rooms/domain/room_repository.dart';
import '../../rooms/presentation/room_detail_page.dart';
import 'activity_card.dart';
import 'widgets/activity_share_sheet.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({
    super.key,
    required this.repository,
    required this.rooms,
    required this.activityId,
  });

  final ActivityRepository repository;
  final RoomRepository rooms;
  final String activityId;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late Future<ActivityView?> _post;
  void _load() => _post = widget.repository.get(widget.activityId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Chi tiết hoạt động',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới',
        ),
      ],
    ),
    body: AsyncPanel<ActivityView?>(
      future: _post,
      onRetry: () => setState(_load),
      builder: (post) {
        if (post == null) {
          return const Center(
            child: Text('Bài đăng không còn khả dụng hoặc đã đổi quyền xem.'),
          );
        }
        return PageContent(
          children: [
            ActivityCard(
              post: post,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => ActivityShareSheet.show(context, post),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Chia sẻ thành tích'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (post.canOpenLog)
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomDetailPage(
                        repository: widget.rooms,
                        roomId: post.roomId,
                      ),
                    ),
                  );
                  if (mounted) setState(_load);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text(
                  'Xem chi tiết phòng chơi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            if (!post.canOpenLog)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Log chi tiết chỉ dành cho thành viên buổi chơi.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
