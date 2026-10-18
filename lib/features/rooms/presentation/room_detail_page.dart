import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import 'room_session_page.dart';
import '../data/mock_room_repository.dart';
import 'mock_room_controls.dart';
import 'room_editor_page.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({
    super.key,
    required this.repository,
    required this.roomId,
  });
  final RoomRepository repository;
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
            MockRoomControls(
              repository: widget.repository,
              onChanged: () {
                _pending = null;
                _error = null;
                setState(_load);
              },
            ),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          room.statusLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${room.visibility} · Bản ${room.revision}',
                        style: AppTokens.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${room.courtName} · ${room.courtLabel}'),
                  Text(room.address, style: AppTokens.label),
                  const SizedBox(height: 6),
                  Text(
                    room.bookingStatus == 'HOST_CONFIRMED'
                        ? 'Host đã khai báo đặt sân · chưa được cơ sở sân xác thực'
                        : 'Chưa xác nhận đặt sân',
                    style: TextStyle(
                      color: room.bookingStatus == 'HOST_CONFIRMED'
                          ? AppColors.primary
                          : AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text(
                    '${room.reserved}/${room.capacity} chỗ chơi · ${room.minElo}–${room.maxElo} Elo',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room.fee} VND/người · phí dự kiến',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Host: ${room.hostName}${room.hostPlays ? ' (có chơi)' : ' (chỉ tổ chức)'}',
                  ),
                  const SizedBox(height: 4),
                  Text('Hạn hủy: ${room.cancelBy.toLocal()}', style: AppTokens.label),
                  if (room.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(room.notes, style: const TextStyle(fontSize: 13)),
                  ],
                  if (room.cancellationReason != null) ...[
                    const SizedBox(height: 8),
                    Text('Lý do hủy: ${room.cancellationReason}', style: const TextStyle(color: AppColors.loss)),
                  ],
                  if (room.myStatus != null) ...[
                    const SizedBox(height: 8),
                    Text('Đăng ký của bạn: ${room.myStatus}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  if (room.myStatus == 'RECONFIRM') ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Điều kiện đã thay đổi. Chỗ vẫn được giữ nhưng lịch mới chỉ được nhận khi bạn xác nhận lại.',
                      style: TextStyle(color: AppColors.streak),
                    ),
                  ],
                  if (room.myStatus == 'WAITLIST') ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Bạn đang chờ; chưa giữ chỗ hoặc giữ lịch. Có thể tự lên chỗ theo thứ tự nếu vẫn đủ điều kiện.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            if (_busy) const LinearProgressIndicator(),
            if (widget.repository is MockRoomRepository &&
                room.status == 'COMPLETED')
              const Text(
                'Trang chủ có nháp từ log cho từng người chơi và nháp tổng kết riêng cho host. Bạn chủ động viết caption và chia sẻ.',
              ),
            if (widget.repository is RoomSessionRepository && room.canEdit)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _execute('booking', payload: {'confirmed': true}),
                child: const Text('Host xác nhận đã liên hệ đặt sân'),
              ),
            if (widget.repository is RoomSessionRepository &&
                (room.isHost || room.myStatus == 'REGISTERED') &&
                ['IN_PROGRESS', 'COMPLETED'].contains(room.status))
              FilledButton(
                onPressed: () =>
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomSessionPage(
                          repository:
                              widget.repository as RoomSessionRepository,
                          roomId: room.id,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) setState(_load);
                    }),
                child: const Text('Trận đấu / Điểm danh'),
              ),
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
                (!room.startsAt.isAfter(DateTime.now()) ||
                    widget.repository is MockRoomRepository)) ...[
              if (room.members.any((m) => m['status'] == 'RECONFIRM'))
                action(
                  'Giải phóng chỗ chưa xác nhận lại (không phạt)',
                  'release_unconfirmed',
                ),
              action(
                widget.repository is MockRoomRepository
                    ? 'Bắt đầu buổi chơi (mock cho phép sớm)'
                    : 'Bắt đầu buổi chơi',
                'start',
              ),
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
