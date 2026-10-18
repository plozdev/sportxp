import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/activity.dart';
import '../../rooms/data/managed_room_repository.dart';
import '../../rooms/data/mock_room_repository.dart';
import '../../rooms/domain/room_repository.dart';
import '../../rooms/presentation/mock_room_controls.dart';
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
  List<ActivityView> _drafts = [];
  bool _mine = false, _loading = false, _more = true;
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
        _drafts = [];
        _more = true;
      }
    });
    try {
      final rows = await widget.repository.list(
        mine: _mine,
        offset: _posts.length,
      );
      final drafts = await widget.repository.drafts();
      if (mounted && gen == _generation) {
        setState(() {
          _posts.addAll(rows);
          _drafts = drafts;
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

  Future<void> _connections() async {
    final rooms = widget.rooms;
    if (rooms is! MockRoomRepository) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Text(
                    'KẾT NỐI BẠN BÈ GIẢ LẬP',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mô phỏng quan hệ bạn bè/chặn trong phiên thử nghiệm.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  for (final entry in rooms.people.entries.where(
                    (p) => p.key != rooms.actorId,
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Bạn hai chiều', style: TextStyle(fontSize: 13)),
                            value: rooms.areFriends(rooms.actorId, entry.key),
                            onChanged: rooms.isBlocked(rooms.actorId, entry.key)
                                ? null
                                : (value) => update(
                                    () => rooms.setMockFriend(entry.key, value),
                                  ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Chặn', style: TextStyle(fontSize: 13, color: AppColors.loss)),
                            value: rooms.isBlocked(rooms.actorId, entry.key),
                            onChanged: (value) =>
                                update(() => rooms.setMockBlock(entry.key, value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) {
      _pending.clear();
      _load(reset: true);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
    children: [
      // Bảng điều khiển mô phỏng tài khoản (tự động ẩn khi lên backend thật)
      MockRoomControls(
        repository: widget.rooms,
        allowReset: true,
        onChanged: () {
          _pending.clear();
          _load(reset: true);
        },
      ),

      // 1. STRAVA-STYLE FEED HEADER & FILTER BAR
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BẢNG TIN THỂ THAO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _mine ? 'Nhật ký thi đấu của tôi' : 'Hoạt động từ bạn bè ra sân',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Tải lại hoạt động',
          ),
          if (widget.rooms is MockRoomRepository)
            TextButton.icon(
              onPressed: _connections,
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('Kết nối giả lập', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),

      const SizedBox(height: 12),

      // Segmented Filter Tabs: [ Bạn bè & tôi ] | [ Bài của tôi ]
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_mine) {
                    setState(() => _mine = false);
                    _load(reset: true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: !_mine ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Bạn bè & tôi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: !_mine ? AppColors.background : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_mine) {
                    setState(() => _mine = true);
                    _load(reset: true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _mine ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Bài của tôi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _mine ? AppColors.background : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
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
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            for (final c in List<ActivityCommand>.from(_pending.values)) {
              await _command(c);
            }
          },
          icon: const Icon(Icons.sync_problem, size: 16),
          label: const Text('Gửi lại thao tác chưa xác nhận'),
        ),
      ],

      const SizedBox(height: 14),

      // 2. STRAVA-STYLE DRAFTS BANNER ("Buổi chơi vừa kết thúc chưa chia sẻ")
      if (_drafts.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.streak.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
              initiallyExpanded: false,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.streak.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.offline_bolt_rounded,
                  size: 20,
                  color: AppColors.streak,
                ),
              ),
              title: Text(
                'Nháp từ log (${_drafts.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              subtitle: const Text(
                'Buổi chơi đã kết thúc · Chia sẻ thành tích lên bảng tin',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              children: [
                const Divider(color: AppColors.border, height: 1),
                for (final draft in _drafts)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: draft.kind == ActivityKind.personal
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.streak.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (draft.kind == ActivityKind.personal
                                          ? AppColors.primary
                                          : AppColors.streak)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      draft.kind == ActivityKind.personal
                                          ? Icons.sports_tennis_rounded
                                          : Icons.groups_rounded,
                                      size: 13,
                                      color: draft.kind == ActivityKind.personal
                                          ? AppColors.primary
                                          : AppColors.streak,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      draft.kind == ActivityKind.personal
                                          ? 'BÀI CÁ NHÂN'
                                          : 'HOST TỔNG KẾT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color: draft.kind == ActivityKind.personal
                                            ? AppColors.primary
                                            : AppColors.streak,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.streak.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CHƯA CHIA SẺ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.streak,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            draft.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 13,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${draft.courtName} • ${_formatTime(draft.playedAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.muted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Strava mini metric strip & Action button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  draft.kind == ActivityKind.personal
                                      ? '${draft.totals.wins ?? 0}W - ${draft.totals.losses ?? 0}L'
                                      : '${draft.totals.confirmed} chốt',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${draft.totals.total} trận',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => _edit(draft),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text(
                                  'Soạn & Đăng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ],

      // 3. EMPTY FEED STATE
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
                width: 64,
                height: 64,
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
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bảng tin thể thao',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chưa có hoạt động được chia sẻ. Bài của bạn và bạn bè sẽ xuất hiện ở đây sau các buổi chơi.',
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

      // 4. ACTIVITY POSTS LIST (Mỗi thẻ mang đậm phong cách Strava)
      for (final post in _posts)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ActivityCard(
            post: post,
            onEdit: () => _edit(post),
            onDelete: _busy.contains(post.id) ? null : () => _delete(post),
            actions: [
              // Nút Kudos / Thả tim thể thao
              OutlinedButton.icon(
                onPressed: _busy.contains(post.id)
                    ? null
                    : () => _command(
                        ActivityCommand(
                          'react',
                          activityId: post.id,
                          liked: !post.liked,
                        ),
                      ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  side: BorderSide(
                    color: post.liked
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                  backgroundColor: post.liked
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                icon: Icon(
                  post.liked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: post.liked ? Colors.redAccent : AppColors.muted,
                ),
                label: Text(
                  '${post.liked ? '♥' : '♡'} ${post.likeCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: post.liked ? Colors.redAccent : AppColors.text,
                  ),
                ),
              ),
              // Nút Mở chi tiết buổi chơi
              FilledButton.tonalIcon(
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(
                  Icons.sports_tennis_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text('Chi tiết'),
              ),
              // Nút Chia sẻ hoạt động Strava-style
              OutlinedButton.icon(
                onPressed: () => ActivityShareSheet.show(context, post),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(
                  Icons.share_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                label: const Text('Chia sẻ'),
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
          child: OutlinedButton.icon(
            onPressed: () => _load(),
            icon: const Icon(Icons.expand_more, size: 18),
            label: const Text('Tải thêm hoạt động'),
          ),
        ),
    ],
  );
}
