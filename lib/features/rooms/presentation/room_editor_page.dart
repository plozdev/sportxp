import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../matchmaking/domain/court.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import 'widgets/room_ui_formatters.dart';

class RoomEditorPage extends StatefulWidget {
  const RoomEditorPage({super.key, required this.repository, this.room});
  final RoomRepository repository;
  final ManagedRoom? room;

  @override
  State<RoomEditorPage> createState() => _RoomEditorPageState();
}

class _RoomEditorPageState extends State<RoomEditorPage> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late Future<List<Court>> _courts;
  late DateTime _start;
  late String _roomCode;
  String? _courtId, _error;
  bool _private = false, _plays = true, _draft = false, _busy = false;
  RoomCommand? _pending;

  TextEditingController field(String name) => _fields[name]!;

  static String _generateRoomCode() {
    return '#XP-${newRoomRequestId().replaceAll('-', '').substring(0, 6).toUpperCase()}';
  }

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _start = room?.startsAt ?? DateTime.now().add(const Duration(hours: 2));
    _courtId = room?.courtId;
    _private = room?.visibility == 'PRIVATE';
    _plays = room?.hostPlays ?? true;
    _draft = room?.status == 'DRAFT';
    _roomCode = room?.roomCode ?? _generateRoomCode();

    final defaults = {
      'Tên buổi chơi': room?.title ?? 'Kèo giao lưu',
      'Thời lượng (phút)':
          '${room?.endsAt.difference(room.startsAt).inMinutes ?? 120}',
      'Số chỗ chơi': '${room?.capacity ?? 4}',
      'Elo tối thiểu': '${room?.minElo ?? 0}',
      'Elo tối đa': '${room?.maxElo ?? 2000}',
      'Phí dự kiến/người (VND)': '${room?.fee ?? 40000}',
      'Hủy miễn ảnh hưởng trước giờ chơi (phút)':
          '${room?.startsAt.difference(room.cancelBy).inMinutes ?? 60}',
      'Sân con / số sân': room?.courtLabel ?? '',
      'Ghi chú / phí đã gồm': room?.notes ?? '',
    };

    for (final e in defaults.entries) {
      _fields[e.key] = TextEditingController(text: e.value);
    }
    _courts = widget.repository.courts();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã phòng $_roomCode'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _regenerateRoomCode() {
    if (widget.room != null) return;
    setState(() {
      _roomCode = _generateRoomCode();
    });
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start.isAfter(now) ? _start : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time != null && mounted) {
      setState(
        () => _start = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  InputDecoration _inputDeco({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      hintStyle: TextStyle(fontSize: 13, color: AppColors.muted.withValues(alpha: 0.6)),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.loss),
      ),
    );
  }

  String? _validateField(String name, String? value) {
    final text = value?.trim() ?? '';
    if (name == 'Tên buổi chơi') {
      return text.isEmpty || text.length > 100
          ? 'Nhập từ 1 đến 100 ký tự.'
          : null;
    }
    if (name == 'Sân con / số sân') {
      return text.length > 100 ? 'Tối đa 100 ký tự.' : null;
    }
    if (name == 'Ghi chú / phí đã gồm') {
      return text.length > 2000 ? 'Tối đa 2000 ký tự.' : null;
    }
    final n = int.tryParse(text);
    if (n == null || n < 0 || n > 2147483647) {
      return 'Nhập số nguyên từ 0 đến 2147483647.';
    }
    if (name == 'Số chỗ chơi' && (n < 2 || n > 100)) {
      return 'Từ 2 đến 100 chỗ.';
    }
    if (name == 'Thời lượng (phút)' && n < 1) {
      return 'Thời lượng phải lớn hơn 0.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_courtId == null || !_start.isAfter(DateTime.now())) {
      setState(() => _error = 'Chọn sân và giờ bắt đầu trong tương lai.');
      return;
    }
    final min = int.parse(field('Elo tối thiểu').text),
        max = int.parse(field('Elo tối đa').text);
    if (max < min) {
      setState(
        () => _error = 'Elo tối đa phải lớn hơn hoặc bằng Elo tối thiểu.',
      );
      return;
    }
    final payload = <String, dynamic>{
      'court_id': _courtId,
      'title': field('Tên buổi chơi').text.trim(),
      'starts_at': _start.toUtc().toIso8601String(),
      'ends_at': _start
          .add(Duration(minutes: int.parse(field('Thời lượng (phút)').text)))
          .toUtc()
          .toIso8601String(),
      'cancel_by': _start
          .subtract(
            Duration(
              minutes: int.parse(
                field('Hủy miễn ảnh hưởng trước giờ chơi (phút)').text,
              ),
            ),
          )
          .toUtc()
          .toIso8601String(),
      'capacity': int.parse(field('Số chỗ chơi').text),
      'min_elo': min,
      'max_elo': max,
      'fee': int.parse(field('Phí dự kiến/người (VND)').text),
      'visibility': _private ? 'PRIVATE' : 'PUBLIC',
      'host_plays': _plays,
      'notes': field('Ghi chú / phí đã gồm').text,
      'court_label': field('Sân con / số sân').text,
      'draft': _draft,
      'room_code': _roomCode,
      if (widget.room != null) 'expected_revision': widget.room!.revision,
    };
    if (_pending == null ||
        jsonEncode(_pending!.payload) != jsonEncode(payload)) {
      _pending = RoomCommand(
        widget.room == null ? 'create' : 'edit',
        roomId: widget.room?.id,
        payload: payload,
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.execute(_pending!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = roomFailure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stepCapacity(int delta) {
    final current = int.tryParse(field('Số chỗ chơi').text) ?? 4;
    final next = (current + delta).clamp(2, 100);
    setState(() {
      field('Số chỗ chơi').text = '$next';
    });
  }

  void _setEloRange(int min, int max) {
    setState(() {
      field('Elo tối thiểu').text = '$min';
      field('Elo tối đa').text = '$max';
    });
  }

  void _appendNote(String text) {
    final current = field('Ghi chú / phí đã gồm').text.trim();
    if (current.contains(text)) return;
    setState(() {
      field('Ghi chú / phí đã gồm').text =
          current.isEmpty ? text : '$current, $text';
    });
  }

  String _formatDisplayStart() {
    final now = DateTime.now();
    final isToday =
        _start.year == now.year &&
        _start.month == now.month &&
        _start.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        _start.year == tomorrow.year &&
        _start.month == tomorrow.month &&
        _start.day == tomorrow.day;

    final datePrefix = isToday
        ? 'Hôm nay'
        : isTomorrow
        ? 'Ngày mai'
        : '${_start.day}/${_start.month}/${_start.year}';
    final timeStr =
        '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
    return '$datePrefix, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final minEloVal = int.tryParse(field('Elo tối thiểu').text) ?? 0;
    final maxEloVal = int.tryParse(field('Elo tối đa').text) ?? 2000;

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.room == null ? 'Tạo buổi chơi' : 'Sửa điều kiện buổi chơi',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.text,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.text),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTokens.contentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.room != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.streak.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.streak.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.streak,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Lưu thay đổi sẽ yêu cầu người đã đăng ký xác nhận lại; danh sách chờ được hủy để đăng ký theo điều kiện mới.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // SECTION 1: LOBBY CODE HERO BANNER
                    _buildLobbyCodeCard(),
                    const SizedBox(height: 16),

                    // SECTION 2: GAME MODE SELECTOR (PUBLIC VS PRIVATE)
                    _buildGameModeSelector(),
                    const SizedBox(height: 16),

                    // SECTION 3: ARENA & MATCH SCHEDULE
                    _buildArenaAndScheduleSection(),
                    const SizedBox(height: 16),

                    // SECTION 4: SLOTS & HOST PARTICIPATION
                    _buildSlotsAndHostSection(),
                    const SizedBox(height: 16),

                    // SECTION 5: RANK / ELO MATCHMAKING BRACKET
                    _buildEloBracketSection(minEloVal, maxEloVal),
                    const SizedBox(height: 16),

                    // SECTION 6: ECONOMICS & ROOM DETAILS
                    _buildEconomicsSection(),
                    const SizedBox(height: 16),

                    // DRAFT TOGGLE & POLICIES
                    if (widget.room == null || widget.room!.status == 'DRAFT')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: SwitchListTile(
                            activeThumbColor: AppColors.primary,
                            title: const Text(
                              'Lưu nháp, chưa mở đăng ký',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Phòng chỉ hiển thị với bạn để chuẩn bị trước.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            value: _draft,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _draft = v),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Phí chỉ là dự kiến, chưa phải thanh toán hay xác nhận đặt sân. Danh sách chờ có thể tự lên chỗ khi còn đủ điều kiện.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),

                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          color: AppColors.loss.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.loss.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.loss,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.loss,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // SUBMIT BUTTON (Strictly maintains 'LƯU BUỔI CHƠI' text for tests)
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _busy ? 'ĐANG LƯU…' : 'LƯU BUỔI CHƠI',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET BUILDER: LOBBY CODE HERO BANNER
  Widget _buildLobbyCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: _private
              ? AppColors.streak.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.sports_esports_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'SẢNH PHÒNG THI ĐẤU',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _private
                      ? AppColors.streak.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _private ? 'PHÒNG KÍN' : 'PHÒNG CÔNG KHAI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _private ? AppColors.streak : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MÃ PHÒNG (ROOM CODE)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _roomCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _copyRoomCode,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Sao chép mã phòng',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                if (widget.room == null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _regenerateRoomCode,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Đổi mã phòng',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.muted,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chia sẻ mã cho người muốn tham gia. Phòng private ẩn khỏi sảnh; public hiện theo khu vực sân.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: GAME MODE SELECTOR (PUBLIC VS PRIVATE)
  Widget _buildGameModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'CHẾ ĐỘ PHÒNG (ROOM VISIBILITY)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // PUBLIC CARD
              Expanded(
                child: InkWell(
                  onTap: _busy ? null : () => setState(() => _private = false),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: !_private
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !_private ? AppColors.primary : AppColors.border,
                        width: !_private ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 20,
                              color: !_private
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            const Spacer(),
                            if (!_private)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Public',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sảnh mở tự do',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hiện ở sảnh theo khu vực sân. Ai đủ điều kiện đều có thể đăng ký.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // PRIVATE CARD
              Expanded(
                child: InkWell(
                  onTap: _busy ? null : () => setState(() => _private = true),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _private
                          ? AppColors.streak.withValues(alpha: 0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _private ? AppColors.streak : AppColors.border,
                        width: _private ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 20,
                              color: _private
                                  ? AppColors.streak
                                  : AppColors.muted,
                            ),
                            const Spacer(),
                            if (_private)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.streak,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Private',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Phòng riêng có mã',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.streak,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ẩn khỏi sảnh. Có mã phòng là có thể tham gia, không cần kết bạn.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_private) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vpn_key_outlined,
                    color: AppColors.streak,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Khóa bảo vệ: Chia sẻ mã $_roomCode cho người muốn tham gia. Nhập mã chỉ mở chi tiết, vẫn kiểm tra trình độ, lịch và số chỗ khi đăng ký.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
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

  // WIDGET BUILDER: ARENA & MATCH SCHEDULE SECTION
  Widget _buildArenaAndScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.stadium_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'SÂN ĐẤU & THỜI GIAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // REFINED COURT SELECTOR (Strictly uses DropdownButtonFormField for test compatibility)
          FutureBuilder<List<Court>>(
            future: _courts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const Text('Chưa tải được sân.'),
                    TextButton(
                      onPressed: () =>
                          setState(() => _courts = widget.repository.courts()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (snapshot.data!.isEmpty) {
                return const Text('Chưa có sân để tạo phòng.');
              }
              return DropdownButtonFormField<String>(
                initialValue: _courtId,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDeco(
                  labelText: 'Sân cầu thi đấu',
                  prefixIcon: const Icon(
                    Icons.place_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                items: snapshot.data!
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sports_tennis_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy ? null : (id) => setState(() => _courtId = id),
                validator: (id) => id == null ? 'Chọn sân.' : null,
              );
            },
          ),
          const SizedBox(height: 12),

          // REFINED SÂN CON / SỐ SÂN
          TextFormField(
            controller: field('Sân con / số sân'),
            enabled: !_busy,
            decoration: _inputDeco(
              labelText: 'Sân con / số sân',
              hintText: 'Ví dụ: Sân 3, Thảm số 1',
              prefixIcon: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            validator: (val) => _validateField('Sân con / số sân', val),
          ),
          const SizedBox(height: 8),

          // QUICK COURT NUMBER PRESETS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final label in [
                  'Sân 1',
                  'Sân 2',
                  'Sân 3',
                  'Sân 4',
                  'Sân 5',
                  'Thảm VIP',
                ]) ...[
                  ActionChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: field('Sân con / số sân').text == label
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            field('Sân con / số sân').text = label;
                          }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // REFINED MATCH START TIME BUTTON
          InkWell(
            onTap: _busy ? null : _pick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời gian bắt đầu thi đấu',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDisplayStart(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Đổi giờ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // MATCH DURATION CHIPS & FIELD
          const Text(
            'Thời lượng trận đấu (phút)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mins in [60, 90, 120, 180]) ...[
                  ChoiceChip(
                    label: Text(
                      mins >= 120 ? '${mins ~/ 60}h (${mins}p)' : '${mins}p',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: field('Thời lượng (phút)').text == '$mins'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: field('Thời lượng (phút)').text == '$mins'
                            ? AppColors.background
                            : AppColors.text,
                      ),
                    ),
                    selected: field('Thời lượng (phút)').text == '$mins',
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: field('Thời lượng (phút)').text == '$mins'
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    showCheckmark: false,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            field('Thời lượng (phút)').text = '$mins';
                          }),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: field('Thời lượng (phút)'),
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: _inputDeco(
              labelText: 'Thời lượng (phút)',
              suffixText: 'phút',
              prefixIcon: const Icon(
                Icons.timelapse_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ),
            validator: (val) => _validateField('Thời lượng (phút)', val),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: SLOTS & HOST PARTICIPATION
  Widget _buildSlotsAndHostSection() {
    final capacity = int.tryParse(field('Số chỗ chơi').text) ?? 4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.people_alt_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'SLOTS THI ĐẤU & VAI TRÒ HOST',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // CAPACITY CONTROLS WITH TACTILE STEPPER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số chỗ thi đấu',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$capacity',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          capacity == 4
                              ? 'người (1 sân đôi)'
                              : capacity == 2
                              ? 'người (1 sân đơn)'
                              : capacity == 6
                              ? 'người (đôi xoay tua)'
                              : capacity == 8
                              ? 'người (2 sân đôi)'
                              : 'người',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _busy || capacity <= 2
                      ? null
                      : () => _stepCapacity(-1),
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: _busy || capacity >= 100
                      ? null
                      : () => _stepCapacity(1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // PRESET CAPACITY CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cap in [2, 4, 6, 8, 12]) ...[
                  ActionChip(
                    label: Text(
                      cap == 2
                          ? '2 chỗ (Đơn)'
                          : cap == 4
                          ? '4 chỗ (Đôi)'
                          : '$cap chỗ',
                      style: TextStyle(
                        fontSize: 11,
                        color: capacity == cap
                            ? AppColors.primary
                            : AppColors.text,
                        fontWeight: capacity == cap
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: capacity == cap
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            field('Số chỗ chơi').text = '$cap';
                          }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // TEXTFIELD FOR CAPACITY
          TextFormField(
            controller: field('Số chỗ chơi'),
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: _inputDeco(
              labelText: 'Số chỗ chơi',
              suffixText: 'chỗ',
              prefixIcon: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ),
            validator: (val) => _validateField('Số chỗ chơi', val),
          ),
          const SizedBox(height: 14),

          // HOST PLAYS TOGGLE (Strictly maintains SwitchListTile with text 'Host cũng chơi' for test compatibility)
          Material(
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _plays
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: SwitchListTile(
              activeThumbColor: AppColors.primary,
              title: const Text(
                'Host cũng chơi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                'Tắt nếu chỉ tổ chức; không chiếm chỗ chơi.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              value: _plays,
              onChanged: _busy ? null : (v) => setState(() => _plays = v),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET BUILDER: RANK / ELO MATCHMAKING BRACKET
  Widget _buildEloBracketSection(int minElo, int maxElo) {
    final skillPreview = RoomUiFormatters.skillRange(minElo, maxElo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.military_tech_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'GIỚI HẠN RANK ELO (MATCHMAKING)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // RANK PREVIEW BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khoảng trình độ cho phép',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skillPreview,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // RANK PRESET CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRankPresetChip('Mọi trình', 0, 2000, minElo, maxElo),
                const SizedBox(width: 6),
                _buildRankPresetChip('Yếu - TB', 400, 800, minElo, maxElo),
                const SizedBox(width: 6),
                _buildRankPresetChip('TB - TBK', 700, 1000, minElo, maxElo),
                const SizedBox(width: 6),
                _buildRankPresetChip('TBK - Khá', 900, 1400, minElo, maxElo),
                const SizedBox(width: 6),
                _buildRankPresetChip('Khá+', 1100, 2000, minElo, maxElo),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // REFINED MIN / MAX ELO INPUT FIELDS
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: field('Elo tối thiểu'),
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco(
                    labelText: 'Elo tối thiểu',
                    suffixText: 'Elo',
                    prefixIcon: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) => _validateField('Elo tối thiểu', val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: field('Elo tối đa'),
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco(
                    labelText: 'Elo tối đa',
                    suffixText: 'Elo',
                    prefixIcon: const Icon(
                      Icons.military_tech_outlined,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) => _validateField('Elo tối đa', val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankPresetChip(
    String label,
    int min,
    int max,
    int currentMin,
    int currentMax,
  ) {
    final isSelected = currentMin == min && currentMax == max;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? AppColors.primary : AppColors.text,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.background,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onPressed: _busy ? null : () => _setEloRange(min, max),
    );
  }

  // WIDGET BUILDER: ECONOMICS & ROOM DETAILS SECTION
  Widget _buildEconomicsSection() {
    final currentFee =
        int.tryParse(field('Phí dự kiến/người (VND)').text) ?? 40000;
    final currentCancel =
        int.tryParse(
          field('Hủy miễn ảnh hưởng trước giờ chơi (phút)').text,
        ) ??
        60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'CHI PHÍ & THÔNG TIN PHÒNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.muted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // TÊN BUỔI CHƠI
          TextFormField(
            controller: field('Tên buổi chơi'),
            enabled: !_busy,
            decoration: _inputDeco(
              labelText: 'Tên buổi chơi',
              hintText: 'Ví dụ: Kèo giao lưu tối thứ 6, Cọ xát leo rank',
              prefixIcon: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            validator: (val) => _validateField('Tên buổi chơi', val),
          ),
          const SizedBox(height: 8),

          // QUICK TITLE PRESETS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final title in [
                  'Kèo giao lưu',
                  'Cọ xát leo rank',
                  'Kèo đôi nam nữ',
                  'Tập luyện kỹ thuật',
                ]) ...[
                  ActionChip(
                    label: Text(
                      title,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: field('Tên buổi chơi').text == title
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            field('Tên buổi chơi').text = title;
                          }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // PHÍ DỰ KIẾN
          const Text(
            'Phí dự kiến / người',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final fee in [0, 30000, 40000, 50000, 70000]) ...[
                  ChoiceChip(
                    label: Text(
                      fee == 0 ? 'Miễn phí' : RoomUiFormatters.currency(fee),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: currentFee == fee
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: currentFee == fee
                            ? AppColors.background
                            : AppColors.text,
                      ),
                    ),
                    selected: currentFee == fee,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: currentFee == fee
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    showCheckmark: false,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            field('Phí dự kiến/người (VND)').text = '$fee';
                          }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: field('Phí dự kiến/người (VND)'),
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: _inputDeco(
              labelText: 'Phí dự kiến/người (VND)',
              suffixText: 'VND',
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: AppColors.streak,
                size: 18,
              ),
            ),
            validator: (val) => _validateField('Phí dự kiến/người (VND)', val),
          ),
          const SizedBox(height: 14),

          // HỦY MIỄN ẢNH HƯỞNG TRƯỚC GIỜ CHƠI
          const Text(
            'Hủy miễn ảnh hưởng trước giờ chơi (phút)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mins in [30, 60, 120, 240]) ...[
                  ActionChip(
                    label: Text(
                      mins >= 60 ? '${mins ~/ 60}h (${mins}p)' : '${mins}p',
                      style: TextStyle(
                        fontSize: 11,
                        color: currentCancel == mins
                            ? AppColors.primary
                            : AppColors.text,
                        fontWeight: currentCancel == mins
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: currentCancel == mins
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            field('Hủy miễn ảnh hưởng trước giờ chơi (phút)')
                                .text = '$mins';
                          }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: field('Hủy miễn ảnh hưởng trước giờ chơi (phút)'),
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: _inputDeco(
              labelText: 'Hủy miễn ảnh hưởng trước giờ chơi (phút)',
              suffixText: 'phút',
              prefixIcon: const Icon(
                Icons.timer_outlined,
                color: AppColors.muted,
                size: 18,
              ),
            ),
            validator: (val) =>
                _validateField('Hủy miễn ảnh hưởng trước giờ chơi (phút)', val),
          ),
          const SizedBox(height: 14),

          // GHI CHÚ / PHÍ ĐÃ GỒM
          TextFormField(
            controller: field('Ghi chú / phí đã gồm'),
            enabled: !_busy,
            maxLines: 2,
            decoration: _inputDeco(
              labelText: 'Ghi chú / dịch vụ đã gồm',
              hintText: 'Ví dụ: Đã gồm tiền sân + 2 ống cầu, nước tự túc.',
              prefixIcon: const Icon(
                Icons.notes_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ),
            validator: (val) => _validateField('Ghi chú / phí đã gồm', val),
          ),
          const SizedBox(height: 8),

          // QUICK AMENITIES CHIPS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in [
                  '+ Tiền cầu',
                  '+ Nước uống',
                  '+ Nhặt cầu',
                  '+ Trọng tài',
                  '+ Chia đều tiền sân',
                ]) ...[
                  ActionChip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _busy ? null : () => _appendNote(tag),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
