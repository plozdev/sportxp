import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../rooms/data/managed_room_repository.dart';
import '../../rooms/domain/room_repository.dart';
import '../domain/activity.dart';
import 'activity_card.dart';
import 'activity_detail_page.dart';
import 'activity_editor_page.dart';
import 'widgets/activity_share_sheet.dart';
import 'widgets/badminton_court_canvas.dart';

enum FeedTab {
  feed, // Bảng tin từ bạn bè & mọi người
  mine, // Bài của tôi đã đăng
  archive, // Kho lưu trữ & Nhật ký thể thao (Strava diary & card sharing)
}

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
  List<ActivityView> _myPublished = [];
  FeedTab _tab = FeedTab.feed;
  int _archiveFilter = 0; // 0: Tất cả, 1: Chờ chia sẻ, 2: Đã đăng
  bool _loading = false, _more = true;
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
        _myPublished = [];
        _more = true;
      }
    });
    try {
      final drafts = await widget.repository.drafts();
      List<ActivityView> rows = [];
      List<ActivityView> myPub = [];

      if (_tab == FeedTab.archive) {
        // Kho lưu trữ tải toàn bộ các bài đã đăng của user và gom với drafts
        myPub = await widget.repository.list(mine: true, offset: 0);
      } else {
        rows = await widget.repository.list(
          mine: _tab == FeedTab.mine,
          offset: _posts.length,
        );
      }

      if (mounted && gen == _generation) {
        setState(() {
          _drafts = drafts;
          if (_tab == FeedTab.archive) {
            _myPublished = myPub;
            _more = false;
          } else {
            _posts.addAll(rows);
            _more = rows.length == 20;
          }
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

  void _switchTab(FeedTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    _load(reset: true);
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Danh sách toàn bộ hoạt động lưu trữ của người dùng (drafts + published)
  List<ActivityView> get _allArchived {
    final list = [..._drafts, ..._myPublished];
    list.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return list;
  }

  List<ActivityView> get _filteredArchived {
    switch (_archiveFilter) {
      case 1:
        return _drafts;
      case 2:
        return _myPublished;
      default:
        return _allArchived;
    }
  }

  int get _totalWins =>
      _allArchived.fold(0, (sum, a) => sum + (a.totals.wins ?? 0));
  int get _totalLosses =>
      _allArchived.fold(0, (sum, a) => sum + (a.totals.losses ?? 0));
  int get _totalMatches =>
      _allArchived.fold(0, (sum, a) => sum + a.totals.total);
  int get _winRate {
    final total = _totalWins + _totalLosses;
    if (total == 0) return 0;
    return ((_totalWins / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
    children: [
      // 1. HEADER CHÍNH
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tab == FeedTab.archive
                      ? 'NHẬT KÝ VẬN ĐỘNG VIÊN'
                      : 'BẢNG TIN THỂ THAO',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tab == FeedTab.archive
                      ? 'Kho lưu trữ & Chia sẻ hoạt động'
                      : _tab == FeedTab.mine
                          ? 'Bài đăng của tôi'
                          : 'Hoạt động từ bạn bè ra sân',
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
        ],
      ),

      const SizedBox(height: 12),

      // 2. SEGMENTED FILTER TABS: [ Bảng tin ] | [ Bài của tôi ] | [ Kho lưu trữ ]
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildTabItem(title: 'Bảng tin', tab: FeedTab.feed),
            _buildTabItem(title: 'Bài của tôi', tab: FeedTab.mine),
            _buildTabItem(
              title: 'Kho lưu trữ',
              tab: FeedTab.archive,
              badgeCount: _drafts.isNotEmpty ? _drafts.length : null,
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

      // 3. TAB BẢNG TIN HOẶC BÀI CỦA TÔI
      if (_tab != FeedTab.archive) ...[
        // STRAVA-STYLE BANNER: "Hoạt động chờ chia sẻ"
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
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
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
                    'Hoạt động chờ chia sẻ (${_drafts.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  subtitle: const Text(
                    'Buổi chơi vừa kết thúc · Chia sẻ thành tích cùng bạn bè',
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
                                      color: AppColors.streak.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SẴN SÀNG CHIA SẺ',
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
                              // Strava metric strip
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
                                      border: Border.all(color: AppColors.border),
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
                                      border: Border.all(color: AppColors.border),
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
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Instant actions with full width and overflow safety
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => ActivityShareSheet.show(
                                        context,
                                        draft,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.share_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      label: const Text(
                                        'Chia sẻ thẻ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _edit(draft),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 9,
                                        ),
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.background,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Đăng bài',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                Text(
                  _tab == FeedTab.mine
                      ? 'Chưa có bài đăng nào'
                      : 'Bảng tin thể thao',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tab == FeedTab.mine
                      ? 'Bạn chưa chia sẻ bài nào lên bảng tin. Mở Kho lưu trữ để chọn buổi chơi và chia sẻ thành tích!'
                      : 'Chưa có hoạt động được chia sẻ. Bài của bạn và bạn bè sẽ xuất hiện ở đây sau các buổi chơi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _tab == FeedTab.mine
                      ? () => _switchTab(FeedTab.archive)
                      : widget.onFindRooms,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(
                    _tab == FeedTab.mine ? Icons.inventory_2_outlined : Icons.search,
                    size: 18,
                  ),
                  label: Text(
                    _tab == FeedTab.mine
                        ? 'Mở Kho lưu trữ hoạt động'
                        : 'Tìm kèo để bắt đầu hoạt động',
                  ),
                ),
              ],
            ),
          ),
        ],

        // POSTS LIST
        for (final post in _posts)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ActivityCard(
              post: post,
              onEdit: () => _edit(post),
              onDelete: _busy.contains(post.id) ? null : () => _delete(post),
              actions: [
                // Kudos / Thả tim thể thao
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
                // Chi tiết buổi chơi
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
                // Chia sẻ Strava Card
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
      ] else ...[
        // 4. TAB KHO LƯU TRỮ HOẠT ĐỘNG (STRAVA ATHLETIC ARCHIVE & SHARE HUB)
        _buildArchiveTabContent(),
      ],

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

      if (!_loading && _more && _posts.isNotEmpty && _tab != FeedTab.archive)
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

  Widget _buildTabItem({
    required String title,
    required FeedTab tab,
    int? badgeCount,
  }) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.background : AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.background
                        : AppColors.streak,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: active
                          ? AppColors.primary
                          : AppColors.background,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Giao diện Kho lưu trữ đậm chất Strava
  Widget _buildArchiveTabContent() {
    final filtered = _filteredArchived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. ATHLETIC SUMMARY BENTO CARD
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG KẾT THI ĐẤU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Nhật ký các buổi chơi đã đồng bộ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),
              // 4 Metrics Grid
              Row(
                children: [
                  _buildMetricCell('Buổi chơi', '${_allArchived.length}'),
                  _buildMetricCell('Số trận', '$_totalMatches'),
                  _buildMetricCell('Thắng - Thua', '$_totalWins-$_totalLosses'),
                  _buildMetricCell(
                    'Tỷ lệ thắng',
                    '$_winRate%',
                    highlight: _winRate >= 50,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. SUB-FILTERS: [ Tất cả ] | [ Chờ chia sẻ ] | [ Đã đăng ]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(0, 'Tất cả (${_allArchived.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(1, 'Chờ chia sẻ (${_drafts.length})'),
              const SizedBox(width: 8),
              _buildFilterChip(2, 'Đã đăng (${_myPublished.length})'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3. ARCHIVE LIST
        if (filtered.isEmpty && !_loading)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kho lưu trữ trống',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chưa có buổi thi đấu nào trong mục này. Khi hoàn thành các buổi chơi, dữ liệu sẽ tự động lưu vào đây để bạn chia sẻ thẻ thành tích.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onFindRooms,
                  icon: const Icon(Icons.sports_tennis_rounded, size: 16),
                  label: const Text('Tìm phòng chơi mới'),
                ),
              ],
            ),
          )
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top: Tag + Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (item.kind == ActivityKind.personal
                                    ? AppColors.primary
                                    : AppColors.streak)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.kind == ActivityKind.personal
                                ? '🏸 CÁ NHÂN'
                                : '👑 HOST BUỔI CHƠI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.kind == ActivityKind.personal
                                  ? AppColors.primary
                                  : AppColors.streak,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.isDraft
                                ? AppColors.streak.withValues(alpha: 0.12)
                                : AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.isDraft
                                ? '⚡ CHỜ CHIA SẺ'
                                : '✓ ĐÃ ĐĂNG BẢNG TIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: item.isDraft
                                  ? AppColors.streak
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Session title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.courtName} • ${_formatTime(item.playedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Strava graphic court preview
                    BadmintonCourtGraphic(post: item, height: 90),

                    const SizedBox(height: 12),

                    // Metric chips
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
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            item.kind == ActivityKind.personal
                                ? '${item.totals.wins ?? 0}W - ${item.totals.losses ?? 0}L'
                                : '${item.totals.confirmed} chốt',
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
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${item.totals.total} trận',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => ActivityShareSheet.show(context, item),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                              ),
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 14),
                            label: const Text(
                              'Chia sẻ thẻ ảnh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.isDraft)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _edit(item),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 14),
                              label: const Text(
                                'Đăng bài',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        else
                          IconButton.filledTonal(
                            onPressed: () async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailPage(
                                    repository: widget.repository,
                                    rooms: widget.rooms,
                                    activityId: item.id,
                                  ),
                                ),
                              );
                              if (mounted) _load(reset: true);
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.text,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.text,
                            ),
                            tooltip: 'Chi tiết bài đăng',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildMetricCell(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.primary : AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final active = _archiveFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _archiveFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
