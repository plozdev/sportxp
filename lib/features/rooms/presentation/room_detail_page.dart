import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import 'room_editor_page.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({
    super.key,
    required this.repository,
    required this.roomId,
  });
  final ManagedRoomRepository repository;
  final String roomId;
  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  late Future<ManagedRoom?> _room;
  RoomCommand? _pending;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _room = widget.repository.get(widget.roomId);
  }

  Future<void> _execute(
    String action, {
    Map<String, dynamic> payload = const {},
  }) async {
    if (_busy) return;
    if (_pending == null ||
        _pending!.action != action ||
        jsonEncode(_pending!.payload) != jsonEncode(payload)) {
      _pending = RoomCommand(action, roomId: widget.roomId, payload: payload);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.execute(_pending!);
      _pending = null;
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) setState(() => _error = roomFailure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(ManagedRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: Text(
          room.myStatus == 'WAITLIST'
              ? 'Rời danh sách chờ không bị ghi là hủy muộn.'
              : room.myStatus == 'RECONFIRM'
              ? 'Bạn từ chối điều kiện mới, không ghi là hủy muộn.'
              : DateTime.now().isAfter(room.cancelBy)
              ? 'Đã qua hạn hủy. Sự kiện hủy muộn sẽ được lưu vào lịch sử đăng ký.'
              : 'Bạn được hủy trước hạn. Chỗ có thể chuyển cho người trong danh sách chờ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) await _execute('leave');
  }

  Future<void> _cancel() async {
    var reason = '';
    final confirm = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy cả buổi chơi'),
        content: TextField(
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Lý do hủy'),
          onChanged: (v) => reason = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.trim().isNotEmpty) {
                Navigator.pop(context, reason.trim());
              }
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirm != null && mounted) {
      await _execute('cancel', payload: {'reason': confirm});
    }
  }

  Future<void> _edit(ManagedRoom room) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RoomEditorPage(repository: widget.repository, room: room),
      ),
    );
    if (mounted) setState(_load);
  }

  Widget action(
    String label,
    String action, {
    Map<String, dynamic> payload = const {},
  }) => OutlinedButton(
    onPressed: _busy ? null : () => _execute(action, payload: payload),
    child: Text(label),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chi tiết buổi chơi'),
      actions: [
        IconButton(
          onPressed: _busy ? null : () => setState(_load),
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại',
        ),
      ],
    ),
    body: AsyncPanel<ManagedRoom?>(
      future: _room,
      onRetry: () => setState(_load),
      builder: (room) {
        if (room == null) {
          return const Center(
            child: Text('Buổi chơi không khả dụng hoặc không có quyền xem.'),
          );
        }
        final time =
            '${room.startsAt.day}/${room.startsAt.month}/${room.startsAt.year} ${TimeOfDay.fromDateTime(room.startsAt).format(context)} → ${TimeOfDay.fromDateTime(room.endsAt).format(context)}';
        return PageContent(
          children: [
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${room.statusLabel} · ${room.visibility} · Bản ${room.revision}',
                  ),
                  Text('${room.courtName} · ${room.courtLabel}'),
                  Text(room.address),
                  Text(time),
                  Text(
                    '${room.reserved}/${room.capacity} chỗ chơi · ${room.minElo}–${room.maxElo} Elo',
                  ),
                  Text('${room.fee} VND/người · phí dự kiến'),
                  Text(
                    'Host: ${room.hostName}${room.hostPlays ? ' (có chơi)' : ' (chỉ tổ chức)'}',
                  ),
                  Text('Hạn hủy: ${room.cancelBy.toLocal()}'),
                  Text(room.notes),
                  if (room.cancellationReason != null)
                    Text('Lý do hủy: ${room.cancellationReason}'),
                  if (room.myStatus != null)
                    Text('Đăng ký của bạn: ${room.myStatus}'),
                  if (room.myStatus == 'RECONFIRM')
                    const Text(
                      'Điều kiện đã thay đổi. Chỗ vẫn được giữ nhưng lịch mới chỉ được nhận khi bạn xác nhận lại.',
                    ),
                  if (room.myStatus == 'WAITLIST')
                    const Text(
                      'Bạn đang chờ; chưa giữ chỗ hoặc giữ lịch. Có thể tự lên chỗ theo thứ tự nếu vẫn đủ điều kiện.',
                    ),
                ],
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (_busy) const LinearProgressIndicator(),
            if (room.canRegister &&
                !room.isHost &&
                ![
                  'REGISTERED',
                  'RECONFIRM',
                  'WAITLIST',
                ].contains(room.myStatus))
              action(
                room.reserved >= room.capacity
                    ? 'Vào danh sách chờ'
                    : 'Đăng ký tham gia',
                room.reserved >= room.capacity ? 'waitlist' : 'join',
                payload: {'expected_revision': room.revision},
              ),
            if (room.canRegister && room.myStatus == 'RECONFIRM')
              action(
                'Đồng ý điều kiện mới',
                'reconfirm',
                payload: {'expected_revision': room.revision},
              ),
            if (!room.isHost &&
                [
                  'REGISTERED',
                  'RECONFIRM',
                  'WAITLIST',
                ].contains(room.myStatus) &&
                ['OPEN', 'FULL'].contains(room.status))
              OutlinedButton(
                onPressed: _busy ? null : () => _leave(room),
                child: Text(
                  room.myStatus == 'RECONFIRM'
                      ? 'Từ chối điều kiện mới'
                      : 'Hủy đăng ký',
                ),
              ),
            if (room.canEdit)
              OutlinedButton(
                onPressed: _busy ? null : () => _edit(room),
                child: const Text('Sửa điều kiện / lịch'),
              ),
            if (room.isHost && room.status == 'DRAFT')
              action('Mở đăng ký', 'publish'),
            if (room.isHost && ['DRAFT', 'OPEN', 'FULL'].contains(room.status))
              OutlinedButton(
                onPressed: _busy ? null : _cancel,
                child: const Text('Hủy buổi chơi'),
              ),
            if (room.isHost &&
                ['OPEN', 'FULL'].contains(room.status) &&
                !room.startsAt.isAfter(DateTime.now())) ...[
              if (room.members.any((m) => m['status'] == 'RECONFIRM'))
                action(
                  'Giải phóng chỗ chưa xác nhận lại (không phạt)',
                  'release_unconfirmed',
                ),
              action('Bắt đầu buổi chơi', 'start'),
            ],
            if (room.isHost && room.status == 'IN_PROGRESS')
              action('Kết thúc buổi (chưa chốt Elo/điểm danh)', 'finish'),
            for (final member in room.members)
              ListTile(
                title: Text(member['name'] as String),
                subtitle: Text(
                  '${member['role']} · ${member['status']} · ${member['is_playing'] == true ? 'Có chơi' : 'Chỉ tổ chức'}${member['cancellation_kind'] == null ? '' : ' · ${member['cancellation_kind']}'}',
                ),
              ),
          ],
        );
      },
    ),
  );
}
