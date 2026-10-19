import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../data/managed_room_repository.dart';
import '../data/mock_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import 'room_detail_page.dart';
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
  // Navigation tabs: 'discover' (Sảnh Public), 'connections' (Phòng Private), 'mine' (Buổi của tôi)
  String _mainTab = 'discover';
  // Sub-tab for 'mine': 'mine' (Sắp tới) or 'history' (Lịch sử)
  String _mineSubTab = 'mine';

  String get _scope => _mainTab == 'mine' ? _mineSubTab : _mainTab;

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

  Future<void> _showJoinByCodeSheet() async {
    final controller = TextEditingController();
    String? localError;
    bool searching = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                children: const [
                  Icon(
                    Icons.vpn_key_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'VÀO PHÒNG BẰNG MÃ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhập mã phòng (ví dụ: #XP-8291) để tìm và tham gia kèo đấu riêng tư hoặc công khai.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'VD: #XP-8291 hoặc 8291',
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 20),
                    tooltip: 'Dán mã',
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data?.text != null) {
                        controller.text = data!.text!.trim();
                      }
                    },
                  ),
                ),
              ),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Text(
                  localError!,
                  style: const TextStyle(
                    color: AppColors.loss,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: searching
                    ? null
                    : () async {
                        final code = controller.text.trim();
                        if (code.isEmpty) {
                          setModalState(
                            () => localError = 'Vui lòng nhập mã phòng.',
                          );
                          return;
                        }
                        setModalState(() {
                          searching = true;
                          localError = null;
                        });
                        try {
                          final room = await widget.repository.get(code);
                          if (!mounted) return;
                          if (room == null) {
                            setModalState(() {
                              searching = false;
                              localError =
                                  'Không tìm thấy phòng với mã "$code".';
                            });
                            return;
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (mounted) _open(room.id);
                        } catch (e) {
                          if (mounted) {
                            setModalState(() {
                              searching = false;
                              localError = roomFailure(e);
                            });
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  searching ? 'ĐANG TÌM PHÒNG…' : 'VÀO PHÒNG NGAY',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // TOP LOBBY HEADER BAR
  Widget _buildTopLobbyBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'SẢNH KÈO ĐẤU',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Quick Join by Code Button
          OutlinedButton.icon(
            onPressed: _showJoinByCodeSheet,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.tag_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            label: const Text(
              'Nhập mã',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.muted,
              side: const BorderSide(color: AppColors.border),
            ),
            tooltip: 'Tải lại sảnh',
          ),
        ],
      ),
    );
  }

  // 3-TAB SEGMENTED CONTROLLER (Public, Private, Mine)
  Widget _buildScopeTabs() {
    final tabs = [
      {'key': 'discover', 'label': 'Sảnh Public', 'icon': Icons.public_rounded},
      {
        'key': 'connections',
        'label': 'Phòng Private',
        'icon': Icons.lock_rounded,
      },
      {'key': 'mine', 'label': 'Buổi của tôi', 'icon': Icons.person_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              for (final t in tabs) ...[
                Expanded(
                  child: InkWell(
                    onTap: _loading
                        ? null
                        : () {
                            if (_mainTab == t['key']) return;
                            setState(() => _mainTab = t['key'] as String);
                            _load(reset: true);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _mainTab == t['key']
                            ? (_mainTab == 'connections'
                                  ? AppColors.streak.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15))
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mainTab == t['key']
                              ? (_mainTab == 'connections'
                                    ? AppColors.streak
                                    : AppColors.primary)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            t['icon'] as IconData,
                            size: 14,
                            color: _mainTab == t['key']
                                ? (_mainTab == 'connections'
                                      ? AppColors.streak
                                      : AppColors.primary)
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _mainTab == t['key']
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _mainTab == t['key']
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (t != tabs.last) const SizedBox(width: 8),
              ],
            ],
          ),

          // SUB-TAB TOGGLE FOR "BUỔI CỦA TÔI" (Sắp tới vs Lịch sử)
          if (_mainTab == 'mine') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Sắp tới', style: TextStyle(fontSize: 11)),
                  selected: _mineSubTab == 'mine',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: _mineSubTab == 'mine'
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  onSelected: _loading
                      ? null
                      : (_) {
                          setState(() => _mineSubTab = 'mine');
                          _load(reset: true);
                        },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Lịch sử', style: TextStyle(fontSize: 11)),
                  selected: _mineSubTab == 'history',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: _mineSubTab == 'history'
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  onSelected: _loading
                      ? null
                      : (_) {
                          setState(() => _mineSubTab = 'history');
                          _load(reset: true);
                        },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // STREAMLINED QUICK FILTER BAR
  Widget _buildQuickFilterBar() {
    if (widget.repository is! MockRoomRepository ||
        (_mainTab != 'discover' && _mainTab != 'connections')) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Filter BottomSheet Opener
          ActionChip(
            avatar: Icon(
              Icons.tune_rounded,
              size: 14,
              color: activeCount > 0 ? AppColors.primary : AppColors.muted,
            ),
            label: Text(
              activeCount > 0 ? 'Bộ lọc ($activeCount)' : 'Bộ lọc',
              style: TextStyle(
                fontSize: 11,
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

          // Available only toggle
          FilterChip(
            label: const Text('Còn chỗ', style: TextStyle(fontSize: 11)),
            selected: _filter.availableOnly,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filter.availableOnly
                  ? AppColors.primary
                  : AppColors.border,
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
              size: 13,
              color: _filter.date != null ? AppColors.primary : AppColors.muted,
            ),
            label: Text(
              _filter.date == null
                  ? 'Ngày chơi'
                  : '${_filter.date!.day}/${_filter.date!.month}',
              style: TextStyle(
                fontSize: 11,
                color: _filter.date != null
                    ? AppColors.primary
                    : AppColors.text,
              ),
            ),
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: _filter.date != null
                  ? AppColors.primary
                  : AppColors.border,
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

          // Reset if active
          if (_filter.hasActiveFilter)
            TextButton.icon(
              onPressed: () {
                setState(() => _filter.reset());
                _load(reset: true);
              },
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Xóa lọc', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.loss,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  // PRIVATE ROOM BANNER (Quick explanation & join CTA)
  Widget _buildPrivateRoomBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.streak.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.streak.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: AppColors.streak,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Phòng riêng bằng mã',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Có mã từ host? Nhập mã để xem và đăng ký, không cần kết bạn.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          FilledButton.tonal(
            onPressed: _showJoinByCodeSheet,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.streak.withValues(alpha: 0.2),
              foregroundColor: AppColors.streak,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Nhập mã',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesBanner() {
    if (_notices.isEmpty) return const SizedBox.shrink();

    final unreadCount = _notices.where((n) => n['read'] != true).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: unreadCount > 0
                ? AppColors.streak.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _noticesExpanded = !_noticesExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    unreadCount > 0
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: unreadCount > 0 ? AppColors.streak : AppColors.muted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      unreadCount > 0
                          ? 'Bạn có $unreadCount thông báo buổi chơi mới'
                          : 'Thông báo buổi chơi (${_notices.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: unreadCount > 0
                            ? AppColors.text
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  Icon(
                    _noticesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_noticesExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            for (final notice in _notices.take(5))
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
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
                  style: const TextStyle(fontSize: 12, color: AppColors.text),
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
                padding: const EdgeInsets.all(8),
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
                    'Đánh dấu đã đọc',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildEmptyState() {
    final icon = switch (_scope) {
      'mine' => Icons.sports_tennis_outlined,
      'history' => Icons.history_toggle_off,
      'connections' => Icons.lock_outline_rounded,
      _ => Icons.search_off_outlined,
    };

    final message = switch (_scope) {
      'mine' => 'Bạn chưa tham gia hoặc làm host buổi chơi nào.',
      'history' => 'Chưa có lịch sử buổi chơi nào hoàn tất.',
      'connections' => 'Chưa có phòng riêng đã tham gia. Nhập mã host chia sẻ để xem và đăng ký!',
      _ =>
        _filter.hasActiveFilter
            ? 'Không tìm thấy kèo phù hợp với bộ lọc.'
            : 'Chưa có buổi chơi nào mở tuyển trong khu vực.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 32, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            if (_mainTab == 'connections')
              FilledButton.icon(
                onPressed: _showJoinByCodeSheet,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                ),
                icon: const Icon(Icons.tag_rounded, size: 16),
                label: const Text('Nhập mã phòng'),
              )
            else if (_filter.hasActiveFilter && _scope == 'discover')
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
        // 1. Top Lobby Bar with "Nhập mã phòng" action
        _buildTopLobbyBar(),

        // 2. Segmented 3-Tab Navigator (Public, Private, Mine)
        _buildScopeTabs(),

        // 3. Quick Filter Bar
        _buildQuickFilterBar(),

        const SizedBox(height: 4),

        // 4. Main List Content
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
                    // Private room info banner when on Private tab
                    if (_mainTab == 'connections') _buildPrivateRoomBanner(),

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
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
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
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.loss,
                                  fontSize: 12,
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
                      RoomCard(room: room, onTap: () => _open(room.id)),
                      const SizedBox(height: 12),
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
                    if (!_loading &&
                        _more &&
                        _error == null &&
                        _items.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => _load(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(
                                180,
                                AppTokens.touchTarget,
                              ),
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
