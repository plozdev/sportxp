import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import 'room_session_page.dart';
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
        height: 48,
        child: FilledButton(
          onPressed: _busy
              ? null
              : () => _execute(actionName, payload: payload),
          style: FilledButton.styleFrom(
            backgroundColor: color ?? AppColors.primary,
            foregroundColor: color == AppColors.streak
                ? Colors.black
                : AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildGroupHeader(IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );

  // KHOẢNG NHÌN ĐẦU: HERO CARD GỌN GÀNG (SÂN, GIỜ, PHÍ, CHỖ TRỐNG & HOST)
  Widget _buildCompactHeroCard(ManagedRoom room) {
    final isCancelled = room.status == 'CANCELLED';
    final isInProgress = room.status == 'IN_PROGRESS';
    final available = (room.capacity - room.reserved).clamp(0, room.capacity);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(
          color: isInProgress
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng huy hiệu: Trạng thái, Mã phòng, Badge của tôi
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? AppColors.loss.withValues(alpha: 0.15)
                        : isInProgress
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
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
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Mã phòng hiển thị rõ trong chi tiết như đề xuất
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        room.visibility == 'PRIVATE'
                            ? Icons.lock_outline_rounded
                            : Icons.tag_rounded,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${room.roomCode}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (room.isHost) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BẠN LÀ HOST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else if (room.myStatus == 'REGISTERED') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ĐÃ VÀO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else if (room.myStatus == 'WAITLIST') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CHỜ CHỖ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.streak,
                      ),
                    ),
                  ),
                ] else if (room.myStatus == 'RECONFIRM') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.loss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CẦN XÁC NHẬN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.loss,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'v${room.revision}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tiêu đề kèo
            Text(
              room.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),

            // 1. SÂN
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.courtLabel.isNotEmpty
                            ? '${room.courtName} • ${room.courtLabel}'
                            : room.courtName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (room.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(room.address, style: AppTokens.label),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 2. GIỜ CHƠI
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    RoomUiFormatters.dateRange(room.startsAt, room.endsAt),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. THÔNG SỐ CHÍNH (3 CỘT GỌN: CHỖ TRỐNG · TRÌNH ĐỘ · PHÍ)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Chỗ trống
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHỖ TRỐNG', style: AppTokens.label),
                        const SizedBox(height: 2),
                        Text(
                          available > 0
                              ? 'Còn $available/${room.capacity}'
                              : 'Đủ người',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: available > 0
                                ? AppColors.primary
                                : AppColors.muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),

                  // Trình độ
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TRÌNH ĐỘ', style: AppTokens.label),
                          const SizedBox(height: 2),
                          Text(
                            RoomUiFormatters.skillRange(
                              room.minElo,
                              room.maxElo,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 26, color: AppColors.border),

                  // Chi phí
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHI PHÍ', style: AppTokens.label),
                          const SizedBox(height: 2),
                          Text(
                            RoomUiFormatters.currency(room.fee),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Host info
            Row(
              children: [
                CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    room.hostName.isNotEmpty
                        ? room.hostName[0].toUpperCase()
                        : 'H',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Host: ${room.hostName} · ${room.hostPlays ? 'Có tham gia' : 'Chỉ tổ chức'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TIẾP PHÍA DƯỚI: ĐẶT SÂN, HẠN HỦY VÀ GHI CHÚ
  Widget _buildBookingAndNotesCard(ManagedRoom room) {
    final isConfirmed = room.bookingStatus == 'HOST_CONFIRMED';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(Icons.info_outline_rounded, 'ĐẶT SÂN & HẠN HỦY'),

          // Trạng thái đặt sân
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isConfirmed ? Icons.verified_outlined : Icons.help_outline,
                  size: 15,
                  color: isConfirmed ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isConfirmed
                        ? 'Host đã khai báo đặt sân'
                        : 'Chưa xác nhận đặt sân',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isConfirmed
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isConfirmed ? AppColors.primary : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Hạn hủy không phạt
          Row(
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 15,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hạn hủy không phạt: ${RoomUiFormatters.deadline(room.cancelBy)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),

          // Ghi chú từ host nếu có
          if (room.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GHI CHÚ TỪ HOST', style: AppTokens.label),
                  const SizedBox(height: 3),
                  Text(
                    room.notes,
                    style: const TextStyle(fontSize: 12, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ],

          // Lý do hủy nếu có
          if (room.cancellationReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.loss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.loss.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LÝ DO HỦY BUỔI',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.loss,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.cancellationReason!,
                    style: const TextStyle(fontSize: 12, color: AppColors.loss),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TIẾP PHÍA DƯỚI: DANH SÁCH NGƯỜI CHƠI
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
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Chưa có thành viên tham gia.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: isHostMember
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.background,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHostMember ? AppColors.primary : AppColors.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
                        fontSize: 13,
                        color: AppColors.text,
                      ),
                    ),
                    if (isHostMember) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
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
                Text(
                  '${status == 'REGISTERED'
                      ? 'Đã vào'
                      : status == 'WAITLIST'
                      ? 'Danh sách chờ'
                      : status} · ${isPlaying ? 'Có chơi' : 'Chỉ tổ chức'}${cancelKind == null ? '' : ' · $cancelKind'}',
                  style: AppTokens.label,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CTA THAM GIA CỐ ĐỊNH Ở ĐÁY MÀN HÌNH (STICKY BOTTOM BAR)
  Widget _buildStickyBottomBar(ManagedRoom room) {
    final isRegistered = [
      'REGISTERED',
      'RECONFIRM',
      'WAITLIST',
    ].contains(room.myStatus);

    Widget? content;

    // Trường hợp 1: Người chơi chưa tham gia -> Nút Đăng ký / Chờ chỗ kèm hiển thị phí
    if (room.canRegister && !room.isHost && !isRegistered) {
      final isFull = room.reserved >= room.capacity;
      content = Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('PHÍ THAM GIA', style: AppTokens.label),
              Text(
                '${RoomUiFormatters.currency(room.fee)}/người',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: action(
              isFull ? 'Vào danh sách chờ' : 'Đăng ký tham gia',
              isFull ? 'waitlist' : 'join',
              payload: {
                'expected_revision': room.revision,
                if (room.visibility == 'PRIVATE') 'room_code': room.roomCode,
              },
              isPrimary: true,
              color: isFull ? AppColors.streak : AppColors.primary,
            ),
          ),
        ],
      );
    }
    // Trường hợp 2: Cần xác nhận điều kiện mới (RECONFIRM)
    else if (room.canRegister && room.myStatus == 'RECONFIRM') {
      content = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _leave(room),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.loss),
                foregroundColor: AppColors.loss,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Từ chối',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: action(
              'Đồng ý điều kiện mới',
              'reconfirm',
              payload: {'expected_revision': room.revision},
              isPrimary: true,
            ),
          ),
        ],
      );
    }
    // Trường hợp 3: Buổi đang diễn ra hoặc đã hoàn tất -> Vào xem trận đấu / Điểm danh
    else if (widget.repository is RoomSessionRepository &&
        (room.isHost || room.myStatus == 'REGISTERED') &&
        ['IN_PROGRESS', 'COMPLETED'].contains(room.status)) {
      content = Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.push<void>(
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
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.sports_tennis),
              label: const Text(
                'Trận đấu / Điểm danh',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          if (room.isHost && room.status == 'IN_PROGRESS') ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _execute('finish'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kết thúc',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      );
    }
    // Trường hợp 4: Host mở đăng ký buổi nháp
    else if (room.isHost && room.status == 'DRAFT') {
      content = action('Mở đăng ký', 'publish', isPrimary: true);
    }
    // Trường hợp 5: Host bắt đầu buổi chơi
    else if (room.isHost &&
        ['OPEN', 'FULL'].contains(room.status) &&
        !room.startsAt.isAfter(DateTime.now())) {
      content = action(
        'Bắt đầu buổi chơi',
        'start',
        isPrimary: true,
      );
    }
    // Trường hợp 6: Đã đăng ký buổi sắp tới -> Có thể hủy đăng ký
    else if (!room.isHost &&
        isRegistered &&
        ['OPEN', 'FULL'].contains(room.status)) {
      content = Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TRẠNG THÁI', style: AppTokens.label),
              Text(
                room.myStatus == 'WAITLIST' ? 'Danh sách chờ' : 'Đã tham gia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: room.myStatus == 'WAITLIST'
                      ? AppColors.streak
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _leave(room),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.loss),
                foregroundColor: AppColors.loss,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hủy đăng ký',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    if (content == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: content,
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
    // CTA tham gia cố định ở đáy màn hình
    bottomNavigationBar: FutureBuilder<ManagedRoom?>(
      future: _room,
      builder: (context, snapshot) {
        final room = snapshot.data;
        if (room == null) return const SizedBox.shrink();
        return _buildStickyBottomBar(room);
      },
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

        return PageContent(
          children: [
            // Khoảng nhìn đầu: Khối tổng quan tinh gọn (Sân, Giờ, Phí, Chỗ & Host)
            _buildCompactHeroCard(room),

            // Tiếp phía dưới: Thông tin đặt sân, hạn hủy và ghi chú
            _buildBookingAndNotesCard(room),

            // Tiếp phía dưới: Người tham gia
            _buildParticipantsCard(room),

            // Thông báo lỗi nếu có
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.loss.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.loss.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.loss, fontSize: 13),
                ),
              ),

            if (_busy) const LinearProgressIndicator(),

            // Thao tác bổ trợ của Host (Xác nhận đặt sân, Sửa lịch, Hủy buổi)
            if (widget.repository is RoomSessionRepository && room.canEdit)
              action(
                'Host xác nhận đã liên hệ đặt sân',
                'booking',
                payload: {'confirmed': true},
                isPrimary: false,
              ),

            if (room.canEdit)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _edit(room),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    AppTokens.touchTarget,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                label: const Text('Sửa điều kiện / lịch'),
              ),

            if (room.isHost &&
                room.members.any((m) => m['status'] == 'RECONFIRM'))
              action(
                'Giải phóng chỗ chưa xác nhận lại (không phạt)',
                'release_unconfirmed',
                isPrimary: false,
              ),

            if (room.isHost && ['DRAFT', 'OPEN', 'FULL'].contains(room.status))
              SizedBox(
                width: double.infinity,
                height: AppTokens.touchTarget,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.loss),
                    foregroundColor: AppColors.loss,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Hủy buổi chơi'),
                ),
              ),
          ],
        );
      },
    ),
  );
}
