import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import 'room_detail_page.dart';
import '../data/mock_room_repository.dart';
import 'mock_room_controls.dart';
import 'widgets/room_card.dart';
import 'widgets/room_filter_sheet.dart';

class ManagedRoomsPage extends StatefulWidget {
  const ManagedRoomsPage({
    super.key,
    required this.repository,
    required this.refreshToken,
  });

  final RoomRepository repository;
  final int refreshToken;

  @override
  State<ManagedRoomsPage> createState() => _ManagedRoomsPageState();
}

class _ManagedRoomsPageState extends State<ManagedRoomsPage> {
  String _scope = 'discover';
  final List<ManagedRoom> _items = [];
  List<Map<String, dynamic>> _notices = [];
  bool _loading = false, _more = true;
  String? _error, _noticeError;
  int _generation = 0;
  bool _noticesExpanded = false;

  final RoomFilterState _filter = RoomFilterState();

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(ManagedRoomsPage old) {
    super.didUpdateWidget(old);
    if (old.refreshToken != widget.refreshToken) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final generation = ++_generation, scope = _scope;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _more = true;
      }
    });

    try {
      final rows = await widget.repository.list(
        scope,
        offset: _items.length,
        search: widget.repository is MockRoomRepository && scope == 'discover'
            ? _filter.toSearch()
            : null,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _items.addAll(rows);
          _more = rows.length == 50;
        });
      }
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = roomFailure(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }

    if (reset) {
      try {
        final rows = await widget.repository.notices();
        if (mounted && generation == _generation) {
          setState(() {
            _notices = rows;
            _noticeError = null;
          });
        }
      } catch (_) {
        if (mounted && generation == _generation) {
          setState(() => _noticeError = 'Chưa tải được thông báo buổi chơi.');
        }
      }
    }
  }

  Future<void> _open(String id) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomDetailPage(repository: widget.repository, roomId: id),
      ),
    );
    if (mounted) _load(reset: true);
  }

  String _noticeText(String kind) => switch (kind) {
    'TERMS_CHANGED' => 'Điều kiện buổi chơi đã đổi; cần xem và xác nhận lại.',
    'PROMOTED' => 'Bạn đã được lên chỗ chính thức từ danh sách chờ.',
    'MEMBER_LEFT' => 'Có người chơi vừa hủy đăng ký.',
    'HOST_CANCELLED' => 'Host đã hủy buổi chơi này.',
    'NOT_RECONFIRMED' =>
      'Chỗ chưa xác nhận lại đã được giải phóng; không phạt.',
    'COMPLETED' => 'Buổi chơi đã kết thúc.',
    'WAITLIST_CLOSED' =>
      'Buổi chơi đã bắt đầu; danh sách chờ đã đóng, không phạt.',
    'WAITLIST_ACCESS_REVOKED' =>
      'Đăng ký chờ đã hủy do thay đổi quyền kết nối; không phạt.',
    _ => kind,
  };

  Widget _buildScopeSelector() {
    final scopes = {
      'discover': 'Tìm kèo',
      'mine': 'Buổi của tôi',
      'history': 'Lịch sử',
      if (widget.repository is MockRoomRepository)
        'connections': 'Kèo riêng bạn bè',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          for (final e in scopes.entries) ...[
            ChoiceChip(
              label: Text(
                e.value,
                style: TextStyle(
                  fontWeight: _scope == e.key ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: _scope == e.key ? AppColors.background : AppColors.text,
                ),
              ),
              selected: _scope == e.key,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: _scope == e.key ? AppColors.primary : AppColors.border,
              ),
              showCheckmark: false,
              onSelected: _loading
                  ? null
                  : (_) {
                      setState(() => _scope = e.key);
                      _load(reset: true);
                    },
            ),
            const SizedBox(width: 8),
          ],
          IconButton.filledTonal(
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.border),
            ),
            tooltip: 'Tải lại',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBar() {
    if (widget.repository is! MockRoomRepository || _scope != 'discover') {
      return const SizedBox.shrink();
    }

    final activeCount = [
      _filter.area != 'Tất cả',
      _filter.radius != 100,
      _filter.date != null,
      _filter.skill != null,
      _filter.maxFee != null,
      _filter.availableOnly,
    ].where((active) => active).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Filter BottomSheet Opener Button
          ActionChip(
            avatar: Icon(
              Icons.tune,
              size: 15,
              color: activeCount > 0 ? AppColors.primary : AppColors.muted,
            ),
            label: Text(
              activeCount > 0 ? 'Bộ lọc ($activeCount)' : 'Bộ lọc',
              style: TextStyle(
                fontSize: 12,
                fontWeight: activeCount > 0 ? FontWeight.w700 : FontWeight.w500,
                color: activeCount > 0 ? AppColors.primary : AppColors.text,
              ),
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: activeCount > 0 ? AppColors.primary : AppColors.border,
            ),
            onPressed: () => RoomFilterSheet.show(
              context: context,
              initial: _filter,
              onApply: (updated) {
                setState(() {
                  _filter.area = updated.area;
                  _filter.radius = updated.radius;
                  _filter.date = updated.date;
                  _filter.skill = updated.skill;
                  _filter.maxFee = updated.maxFee;
                  _filter.availableOnly = updated.availableOnly;
                });
                _load(reset: true);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Available only quick toggle
          FilterChip(
            label: const Text('Còn chỗ', style: TextStyle(fontSize: 12)),
            selected: _filter.availableOnly,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filter.availableOnly ? AppColors.primary : AppColors.border,
            ),
            onSelected: (val) {
              setState(() => _filter.availableOnly = val);
              _load(reset: true);
            },
          ),
          const SizedBox(width: 8),

          // Date quick filter
          ActionChip(
            avatar: Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: _filter.date != null ? AppColors.primary : AppColors.muted,
            ),
            label: Text(
              _filter.date == null
                  ? 'Ngày chơi'
                  : '${_filter.date!.day}/${_filter.date!.month}',
              style: TextStyle(
                fontSize: 12,
                color: _filter.date != null ? AppColors.primary : AppColors.text,
              ),
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filter.date != null ? AppColors.primary : AppColors.border,
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _filter.date ?? now,
                firstDate: DateTime(now.year, now.month, now.day),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _filter.date = picked);
                _load(reset: true);
              }
            },
          ),
          const SizedBox(width: 8),

          // Area quick chip if selected
          if (_filter.area != 'Tất cả') ...[
            Chip(
              label: Text(_filter.area, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                setState(() => _filter.area = 'Tất cả');
                _load(reset: true);
              },
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],

          // Reset all if any filter is active
          if (_filter.hasActiveFilter)
            TextButton.icon(
              onPressed: () {
                setState(() => _filter.reset());
                _load(reset: true);
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Xóa lọc', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.loss,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoticesBanner() {
    if (_notices.isEmpty) return const SizedBox.shrink();

    final unreadCount = _notices.where((n) => n['read'] != true).length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unreadCount > 0
              ? AppColors.streak.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _noticesExpanded = !_noticesExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: unreadCount > 0 ? AppColors.streak : AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thông báo buổi chơi${unreadCount > 0 ? ' ($unreadCount chưa đọc)' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: unreadCount > 0 ? AppColors.text : AppColors.muted,
                      ),
                    ),
                  ),
                  Icon(
                    _noticesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_noticesExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            for (final notice in _notices)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: notice['read'] == true
                        ? Colors.transparent
                        : AppColors.streak,
                  ),
                ),
                title: Text(
                  _noticeText(notice['kind'] as String),
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                ),
                subtitle: Text(
                  'Bản ${notice['revision']} • ${notice['created_at']}',
                  style: AppTokens.label,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.muted,
                ),
                onTap: () => _open(notice['room_id'] as String),
              ),
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      await widget.repository.readNotices(
                        (_notices.first['id'] as num).toInt(),
                      );
                      if (mounted) _load(reset: true);
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => _noticeError = 'Chưa thể đánh dấu đã đọc.',
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text(
                    'Đánh dấu đã đọc các thông báo',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final icon = switch (_scope) {
      'mine' => Icons.sports_tennis_outlined,
      'history' => Icons.history_toggle_off,
      'connections' => Icons.group_outlined,
      _ => Icons.search_off_outlined,
    };

    final message = switch (_scope) {
      'mine' => 'Bạn chưa tham gia hoặc làm host buổi chơi nào.',
      'history' => 'Chưa có lịch sử buổi chơi nào hoàn tất.',
      'connections' => 'Chưa có kèo riêng nào từ bạn bè hai chiều.',
      _ => _filter.hasActiveFilter
          ? 'Không tìm thấy kèo phù hợp với bộ lọc.'
          : 'Chưa có buổi chơi nào mở tuyển trong khu vực.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 36, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            if (_filter.hasActiveFilter && _scope == 'discover')
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _filter.reset());
                  _load(reset: true);
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Xóa bộ lọc'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: Column(
      children: [
        // Scope Navigation Bar
        _buildScopeSelector(),

        // Quick Filter Bar
        _buildQuickFilterBar(),

        const SizedBox(height: 4),

        // Main List Content
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => _load(reset: true),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTokens.contentWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    // Notices Banner
                    _buildNoticesBanner(),

                    if (_noticeError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _noticeError!,
                          style: const TextStyle(
                            color: AppColors.loss,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.loss.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.loss.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.loss,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.loss,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _load(reset: true),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),

                    // Room Cards
                    for (final room in _items) ...[
                      RoomCard(
                        room: room,
                        onTap: () => _open(room.id),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Loading State
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    // Empty State
                    if (_items.isEmpty && !_loading && _error == null)
                      _buildEmptyState(),

                    // Pagination Load More Button
                    if (!_loading && _more && _error == null && _items.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => _load(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(180, AppTokens.touchTarget),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: AppColors.muted,
                            ),
                            label: const Text(
                              'TẢI THÊM BUỔI CHƠI',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
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
      ],
    ),
  );
}
