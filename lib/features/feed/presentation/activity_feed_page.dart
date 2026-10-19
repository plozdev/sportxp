import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../rooms/data/managed_room_repository.dart';
import '../../rooms/domain/room_repository.dart';
import '../domain/activity.dart';
import 'activity_card.dart';
import 'activity_detail_page.dart';
import 'activity_editor_page.dart';
import 'widgets/activity_share_sheet.dart';

class ActivityFeedPage extends StatefulWidget {
  const ActivityFeedPage({
    super.key,
    required this.repository,
    required this.rooms,
    required this.refreshToken,
    required this.onFindRooms,
  });

  final ActivityRepository repository;
  final RoomRepository rooms;
  final int refreshToken;
  final VoidCallback onFindRooms;

  @override
  State<ActivityFeedPage> createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage> {
  final List<ActivityView> _posts = [];
  bool _loading = false;
  bool _more = true;
  String? _error;
  int _generation = 0;
  final Set<String> _busy = {};
  final Map<String, ActivityCommand> _pending = {};

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(ActivityFeedPage old) {
    super.didUpdateWidget(old);
    if (old.refreshToken != widget.refreshToken) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _posts.clear();
        _more = true;
      }
    });
    try {
      // Home chỉ có một dòng hoạt động của bạn và bạn bè, mới nhất trước
      final rows = await widget.repository.list(
        mine: false,
        offset: reset ? 0 : _posts.length,
      );

      if (mounted && gen == _generation) {
        setState(() {
          _posts.addAll(rows);
          _more = rows.length == 20;
        });
      }
    } catch (e) {
      if (mounted && gen == _generation) {
        setState(() => _error = roomFailure(e));
      }
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _edit(ActivityView post) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ActivityEditorPage(repository: widget.repository, post: post),
      ),
    );
    if (mounted) _load(reset: true);
  }

  Future<void> _command(ActivityCommand command) async {
    if (_busy.contains(command.activityId)) return;
    _pending[command.activityId] = command;
    setState(() => _busy.add(command.activityId));
    try {
      await widget.repository.execute(command);
      _pending.remove(command.activityId);
      if (mounted) await _load(reset: true);
    } catch (e) {
      if (mounted) setState(() => _error = roomFailure(e));
    } finally {
      if (mounted) setState(() => _busy.remove(command.activityId));
    }
  }

  Future<void> _delete(ActivityView post) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa bài đăng?'),
        content: const Text(
          'Chỉ xóa bài viết chia sẻ; dữ liệu kết quả trận và điểm danh buổi chơi vẫn được bảo toàn nguyên vẹn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa bài'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await _command(
        ActivityCommand(
          'delete',
          activityId: post.id,
          expectedVersion: post.version,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView(
        // Phần đầu Home rất ngắn: padding nhỏ, ngay lập tức tới activity đầu tiên
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          if (_error != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.loss),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.loss, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_pending.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                onPressed: () async {
                  for (final c in List<ActivityCommand>.from(_pending.values)) {
                    await _command(c);
                  }
                },
                icon: const Icon(Icons.sync_problem, size: 16),
                label: const Text('Gửi lại thao tác chưa xác nhận'),
              ),
            ),
          ],

          // EMPTY FEED STATE
          if (_posts.isEmpty && !_loading) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_tennis_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bảng tin thể thao',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chưa có hoạt động được chia sẻ. Hoạt động của bạn và bạn bè sẽ xuất hiện ở đây sau các buổi chơi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: widget.onFindRooms,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Tìm kèo để bắt đầu hoạt động'),
                  ),
                ],
              ),
            ),
          ],

          // POSTS STREAM (MỚI NHẤT TRƯỚC)
          for (final post in _posts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityCard(
                post: post,
                onEdit: () => _edit(post),
                onDelete: _busy.contains(post.id) ? null : () => _delete(post),
                actions: [
                  // 1. Thích / Kudos
                  TextButton.icon(
                    onPressed: _busy.contains(post.id)
                        ? null
                        : () => _command(
                            ActivityCommand(
                              'react',
                              activityId: post.id,
                              liked: !post.liked,
                            ),
                          ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: post.liked ? Colors.redAccent : AppColors.muted,
                    ),
                    icon: Icon(
                      post.liked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: post.liked ? Colors.redAccent : AppColors.muted,
                    ),
                    label: Text(
                      '${post.liked ? 'Đã thích' : 'Thích'} ${post.likeCount > 0 ? '(${post.likeCount})' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: post.liked ? Colors.redAccent : AppColors.text,
                      ),
                    ),
                  ),
                  // 2. Chi tiết
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActivityDetailPage(
                            repository: widget.repository,
                            rooms: widget.rooms,
                            activityId: post.id,
                          ),
                        ),
                      );
                      if (mounted) _load(reset: true);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: AppColors.muted,
                    ),
                    icon: const Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  // 3. Chia sẻ
                  TextButton.icon(
                    onPressed: () => ActivityShareSheet.show(context, post),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      foregroundColor: AppColors.muted,
                    ),
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    label: const Text(
                      'Chia sẻ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          if (!_loading && _more && _posts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: const Text('Tải thêm hoạt động'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
