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
import 'widgets/room_ui_formatters.dart';

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
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
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
    String actionName, {
    Map<String, dynamic> payload = const {},
    bool isPrimary = false,
    Color? color,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: _busy ? null : () => _execute(actionName, payload: payload),
          style: FilledButton.styleFrom(
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: color == AppColors.streak ? Colors.black : AppColors.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: AppTokens.touchTarget,
      child: OutlinedButton(
        onPressed: _busy ? null : () => _execute(actionName, payload: payload),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? AppColors.border),
          foregroundColor: color ?? AppColors.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildGroupHeader(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  Widget _buildOverviewCard(ManagedRoom room) {
    final isPrivate = room.visibility == 'PRIVATE';
    final isCancelled = room.status == 'CANCELLED';
    final isInProgress = room.status == 'IN_PROGRESS';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges & Visibility row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppColors.loss.withValues(alpha: 0.15)
                      : isInProgress
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCancelled
                        ? AppColors.loss.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  room.statusLabel,
                  style: TextStyle(
                    color: isCancelled ? AppColors.loss : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrivate ? Icons.lock_outline : Icons.public,
                      size: 13,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPrivate ? 'Phòng riêng bằng mã' : 'Kèo công khai',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'v${room.revision}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            room.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              height: 1.3,
            ),
          ),

          // Personal Status Alert / Banner
          if (room.isHost) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Bạn là Host của buổi chơi này',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (room.myStatus == 'REGISTERED') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Bạn đã đăng ký tham gia buổi này',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (room.myStatus == 'WAITLIST') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.streak.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.streak.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.streak),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đang ở danh sách chờ; sẽ tự động lên chỗ nếu có người hủy.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.streak,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (room.myStatus == 'RECONFIRM') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.loss),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Điều kiện buổi chơi đã thay đổi. Chỗ vẫn được giữ nhưng bạn cần xác nhận lại lịch mới.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.loss,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Nhóm 1: Sân và thời gian
  Widget _buildVenueAndTimeCard(ManagedRoom room) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(Icons.location_on_outlined, 'SÂN VÀ THỜI GIAN'),

          // Court name & court label
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.sports_tennis, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.courtName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (room.courtLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          room.courtLabel.startsWith('Sân') ? room.courtLabel : 'Sân ${room.courtLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (room.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(room.address, style: AppTokens.label),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),

          // Time range formatted
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.schedule, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RoomUiFormatters.dateRange(room.startsAt, room.endsAt),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khung giờ địa phương • Có mặt trước 10 phút để khởi động',
                      style: AppTokens.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nhóm 2: Chỗ trống và trình độ
  Widget _buildSlotsAndSkillCard(ManagedRoom room) {
    final available = (room.capacity - room.reserved).clamp(0, room.capacity);

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(Icons.groups_outlined, 'CHỖ TRỐNG VÀ TRÌNH ĐỘ'),

          // Slots metric row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TÌNH TRẠNG CHỖ', style: AppTokens.label),
                    const SizedBox(height: 4),
                    Text(
                      available > 0 ? 'CÒN $available CHỖ' : 'ĐÃ ĐỦ NGƯỜI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: available > 0 ? AppColors.primary : AppColors.muted,
                        letterSpacing: 0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '${room.reserved}/${room.capacity} người chơi đã vào',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YÊU CẦU TRÌNH ĐỘ', style: AppTokens.label),
                      const SizedBox(height: 4),
                      Text(
                        RoomUiFormatters.skillRange(room.minElo, room.maxElo),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        room.minElo <= 0 && room.maxElo >= 2000
                            ? 'Giao lưu mở rộng'
                            : '${room.minElo}–${room.maxElo} Elo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),

          // Host & participation mode
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Host: ${room.hostName} · ${room.hostPlays ? 'Có tham gia thi đấu' : 'Chỉ tổ chức (không chiếm slot)'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Nhóm 3: Chi phí, hạn hủy và tình trạng đặt sân
  Widget _buildPricingAndBookingCard(ManagedRoom room) {
    final isConfirmed = room.bookingStatus == 'HOST_CONFIRMED';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(Icons.payments_outlined, 'CHI PHÍ VÀ ĐẶT SÂN'),

          // Fee row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chi phí dự kiến', style: TextStyle(fontSize: 14, color: AppColors.text)),
              Text(
                '${RoomUiFormatters.currency(room.fee)} / người',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Booking status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isConfirmed ? Icons.verified_outlined : Icons.help_outline,
                  size: 16,
                  color: isConfirmed ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isConfirmed
                        ? 'Host đã khai báo đặt sân (chưa qua sân xác thực)'
                        : 'Chưa xác nhận đặt sân',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isConfirmed ? FontWeight.w600 : FontWeight.normal,
                      color: isConfirmed ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cancellation deadline formatted
          Row(
            children: [
              const Icon(Icons.event_busy_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hạn hủy không phạt: ${RoomUiFormatters.deadline(room.cancelBy)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),

          // Notes if present
          if (room.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GHI CHÚ TỪ HOST', style: AppTokens.label),
                  const SizedBox(height: 4),
                  Text(room.notes, style: const TextStyle(fontSize: 13, color: AppColors.text)),
                ],
              ),
            ),
          ],

          // Cancellation reason if present
          if (room.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LÝ DO HỦY BUỔI', style: TextStyle(fontSize: 11, color: AppColors.loss, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    room.cancellationReason!,
                    style: const TextStyle(fontSize: 13, color: AppColors.loss),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Nhóm 4: Người tham gia
  Widget _buildParticipantsCard(ManagedRoom room) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(
            Icons.people_alt_outlined,
            'NGƯỜI THAM GIA (${room.members.length}/${room.capacity})',
          ),
          if (room.members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có thành viên tham gia.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            )
          else
            for (int index = 0; index < room.members.length; index++) ...[
              if (index > 0) const Divider(height: 1, color: AppColors.border),
              _buildMemberRow(room.members[index]),
            ],
        ],
      ),
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    final name = member['name'] as String? ?? 'Người chơi';
    final role = member['role'] as String? ?? 'MEMBER';
    final status = member['status'] as String? ?? 'REGISTERED';
    final isPlaying = member['is_playing'] == true;
    final cancelKind = member['cancellation_kind'] as String?;
    final isHostMember = role == 'HOST';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar with initial
          CircleAvatar(
            radius: 18,
            backgroundColor: isHostMember
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.background,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHostMember ? AppColors.primary : AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    if (isHostMember) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${status == 'REGISTERED' ? 'Đã vào' : status == 'WAITLIST' ? 'Danh sách chờ' : status} · ${isPlaying ? 'Có chơi' : 'Chỉ tổ chức'}${cancelKind == null ? '' : ' · $cancelKind'}',
                  style: AppTokens.label,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
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

        final isRegistered = ['REGISTERED', 'RECONFIRM', 'WAITLIST'].contains(room.myStatus);

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

            // Overview Card
            _buildOverviewCard(room),

            // Nhóm 1: Sân và thời gian
            _buildVenueAndTimeCard(room),

            // Nhóm 2: Chỗ trống và trình độ
            _buildSlotsAndSkillCard(room),

            // Nhóm 3: Chi phí, hạn hủy và tình trạng đặt sân
            _buildPricingAndBookingCard(room),

            // Nhóm 4: Người tham gia
            _buildParticipantsCard(room),

            // Error notice if any
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.loss.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.loss, fontSize: 13)),
              ),

            if (_busy) const LinearProgressIndicator(),

            if (widget.repository is MockRoomRepository && room.status == 'COMPLETED')
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Buổi chơi đã kết thúc. Bạn có thể mở Trang chủ hoặc mục Lưu trữ để xem hoạt động và chia sẻ thẻ thành tích lên bảng tin.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),

            // Action: Host xác nhận đặt sân
            if (widget.repository is RoomSessionRepository && room.canEdit)
              action(
                'Host xác nhận đã liên hệ đặt sân',
                'booking',
                payload: {'confirmed': true},
                isPrimary: false,
              ),

            // Action: Trận đấu / Điểm danh (trong buổi đang diễn ra hoặc hoàn tất)
            if (widget.repository is RoomSessionRepository &&
                (room.isHost || room.myStatus == 'REGISTERED') &&
                ['IN_PROGRESS', 'COMPLETED'].contains(room.status))
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomSessionPage(
                        repository: widget.repository as RoomSessionRepository,
                        roomId: room.id,
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(_load);
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.sports_tennis),
                  label: const Text(
                    'Trận đấu / Điểm danh',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),

            // Primary Registration Action Button
            if (room.canRegister && !room.isHost && !isRegistered)
              action(
                room.reserved >= room.capacity
                    ? 'Vào danh sách chờ'
                    : 'Đăng ký tham gia',
                room.reserved >= room.capacity ? 'waitlist' : 'join',
                payload: {
                  'expected_revision': room.revision,
                  if (room.visibility == 'PRIVATE') 'room_code': room.roomCode,
                },
                isPrimary: true,
                color: room.reserved >= room.capacity ? AppColors.streak : AppColors.primary,
              ),

            // Reconfirm Action Button
            if (room.canRegister && room.myStatus == 'RECONFIRM')
              action(
                'Đồng ý điều kiện mới',
                'reconfirm',
                payload: {'expected_revision': room.revision},
                isPrimary: true,
                color: AppColors.primary,
              ),

            // Leave / Reject Action Button
            if (!room.isHost && isRegistered && ['OPEN', 'FULL'].contains(room.status))
              SizedBox(
                width: double.infinity,
                height: AppTokens.touchTarget,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _leave(room),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.loss),
                    foregroundColor: AppColors.loss,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    room.myStatus == 'RECONFIRM'
                        ? 'Từ chối điều kiện mới'
                        : 'Hủy đăng ký',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            // Host Actions: Edit, Publish, Cancel, Start, Finish
            if (room.canEdit)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _edit(room),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTokens.touchTarget),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                label: const Text('Sửa điều kiện / lịch'),
              ),

            if (room.isHost && room.status == 'DRAFT')
              action('Mở đăng ký', 'publish', isPrimary: true),

            if (room.isHost && ['DRAFT', 'OPEN', 'FULL'].contains(room.status))
              SizedBox(
                width: double.infinity,
                height: AppTokens.touchTarget,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.loss),
                    foregroundColor: AppColors.loss,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Hủy buổi chơi'),
                ),
              ),

            if (room.isHost &&
                ['OPEN', 'FULL'].contains(room.status) &&
                (!room.startsAt.isAfter(DateTime.now()) ||
                    widget.repository is MockRoomRepository)) ...[
              if (room.members.any((m) => m['status'] == 'RECONFIRM'))
                action(
                  'Giải phóng chỗ chưa xác nhận lại (không phạt)',
                  'release_unconfirmed',
                  isPrimary: false,
                ),
              action(
                widget.repository is MockRoomRepository
                    ? 'Bắt đầu buổi chơi (mock cho phép sớm)'
                    : 'Bắt đầu buổi chơi',
                'start',
                isPrimary: true,
              ),
            ],

            if (room.isHost && room.status == 'IN_PROGRESS')
              action('Kết thúc buổi (chưa chốt Elo/điểm danh)', 'finish', isPrimary: true),
          ],
        );
      },
    ),
  );
}
