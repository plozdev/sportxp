import 'package:flutter/material.dart';

import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import 'room_detail_page.dart';

class ManagedRoomsPage extends StatefulWidget {
  const ManagedRoomsPage({
    super.key,
    required this.repository,
    required this.refreshToken,
  });
  final ManagedRoomRepository repository;
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
      final rows = await widget.repository.list(scope, offset: _items.length);
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
    'TERMS_CHANGED' => 'Điều kiện đã đổi; cần xem và xác nhận lại.',
    'PROMOTED' => 'Bạn đã được lên chỗ từ danh sách chờ.',
    'MEMBER_LEFT' => 'Có người hủy đăng ký.',
    'HOST_CANCELLED' => 'Host đã hủy buổi chơi.',
    'NOT_RECONFIRMED' =>
      'Chỗ chưa xác nhận lại đã được giải phóng; không phạt.',
    'COMPLETED' => 'Buổi chơi đã kết thúc.',
    'WAITLIST_CLOSED' =>
      'Buổi chơi đã bắt đầu; danh sách chờ được đóng, không phạt.',
    'WAITLIST_ACCESS_REVOKED' =>
      'Đăng ký chờ đã hủy do thay đổi quyền kết nối; không phạt.',
    _ => kind,
  };
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final e in const {
              'discover': 'Tìm kèo',
              'mine': 'Buổi của tôi',
              'history': 'Lịch sử',
            }.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _scope == e.key,
                onSelected: _loading
                    ? null
                    : (_) {
                        _scope = e.key;
                        _load(reset: true);
                      },
              ),
            IconButton(
              onPressed: () => _load(reset: true),
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại buổi chơi',
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            if (_noticeError != null) Text(_noticeError!),
            if (_notices.isNotEmpty)
              ExpansionTile(
                title: Text(
                  'Thông báo buổi chơi (${_notices.where((n) => n['read'] != true).length} chưa đọc)',
                ),
                children: [
                  for (final notice in _notices)
                    ListTile(
                      title: Text(_noticeText(notice['kind'] as String)),
                      subtitle: Text(
                        'Bản ${notice['revision']} · ${notice['created_at']}',
                      ),
                      onTap: () => _open(notice['room_id'] as String),
                    ),
                  TextButton(
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
                    child: const Text('Đánh dấu đã đọc các thông báo hiện có'),
                  ),
                ],
              ),
            if (_error != null) Text(_error!),
            if (_items.isEmpty && !_loading && _error == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có buổi chơi trong mục này.'),
              ),
            for (final room in _items)
              Card(
                child: ListTile(
                  title: Text('${room.title} · ${room.statusLabel}'),
                  subtitle: Text(
                    '${room.courtName} · ${room.visibility}\n${room.startsAt.toLocal()} → ${room.endsAt.toLocal()}\n'
                    '${room.reserved}/${room.capacity} chỗ · ${room.minElo}–${room.maxElo} Elo · ${room.fee} VND/người'
                    '${room.myStatus == null ? '' : '\nĐăng ký: ${room.myStatus}'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(room.id),
                ),
              ),
            if (_loading) const LinearProgressIndicator(),
            if (!_loading && _more && _error == null)
              TextButton(
                onPressed: () => _load(),
                child: const Text('Tải thêm'),
              ),
          ],
        ),
      ),
    ],
  );
}
