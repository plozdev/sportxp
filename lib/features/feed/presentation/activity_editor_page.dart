import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/activity.dart';
import '../../rooms/data/managed_room_repository.dart';
import 'activity_card.dart';

class ActivityEditorPage extends StatefulWidget {
  const ActivityEditorPage({
    super.key,
    required this.repository,
    required this.post,
  });

  final ActivityRepository repository;
  final ActivityView post;

  @override
  State<ActivityEditorPage> createState() => _ActivityEditorPageState();
}

class _ActivityEditorPageState extends State<ActivityEditorPage> {
  late final TextEditingController _caption;
  late ActivityAudience _audience;
  bool _preview = false, _busy = false;
  String? _error;
  ActivityCommand? _pending;

  final List<String> _quickTags = [
    '🔥 Smash cháy sân',
    '⚡ Thắng kịch tính',
    '🤝 Đồng đội ăn ý',
    '🏸 Set 3 cân não',
    '💪 Thể lực sung mãn',
    '🎯 Điều cầu chuẩn xác',
  ];

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.post.caption);
    _audience = widget.post.audience;
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _addQuickTag(String tag) {
    final current = _caption.text.trim();
    final newText = current.isEmpty ? tag : '$current · $tag';
    _caption.text = newText;
    _caption.selection = TextSelection.fromPosition(
      TextPosition(offset: _caption.text.length),
    );
    setState(() => _preview = false);
  }

  Future<void> _save(String action) async {
    if (_busy) return;
    if (_caption.text.trim().length > 2000) {
      setState(() => _error = 'Caption tối đa 2000 ký tự.');
      return;
    }
    if (_pending == null ||
        _pending!.action != action ||
        _pending!.caption != _caption.text.trim() ||
        _pending!.audience != _audience) {
      _pending = ActivityCommand(
        action,
        activityId: widget.post.id,
        expectedVersion: widget.post.version,
        caption: _caption.text.trim(),
        audience: _audience,
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

  @override
  Widget build(BuildContext context) {
    final stats = widget.post.totals;
    final isPersonal = widget.post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post.isDraft ? 'Chia sẻ hoạt động' : 'Chỉnh bài đăng',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          if (widget.post.isDraft)
            TextButton(
              onPressed: _busy ? null : () => _save('save'),
              child: const Text('Lưu nháp'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STRAVA-STYLE WORKOUT SUMMARY HEADER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.sports_tennis_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.post.courtName} • ${widget.post.playedAt.day}/${widget.post.playedAt.month}/${widget.post.playedAt.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge chỉ số
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          isPersonal
                              ? '${wins}W - ${losses}L'
                              : '${stats.confirmed}/${stats.total} chốt',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isPersonal && wins >= losses
                                ? AppColors.primary
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'ĐỒNG BỘ TỰ ĐỘNG · Kết quả từ phòng thi đấu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. CAPTION & ATHLETE FEELING (Cảm nhận buổi chơi)
            const Text(
              'CẢM NHẬN BUỔI CHƠI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _caption,
                    enabled: !_busy,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    onChanged: (_) => setState(() => _preview = false),
                    style: const TextStyle(fontSize: 14, color: AppColors.text),
                    decoration: const InputDecoration(
                      hintText:
                          'Hôm nay cảm giác thi đấu thế nào? Cầu bay nhanh hay chậm? Đồng đội phối hợp ra sao...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      labelText: 'Cảm nhận về buổi chơi',
                      labelStyle: TextStyle(color: AppColors.muted),
                    ),
                  ),

                  // Quick Suggestion Chips
                  const SizedBox(height: 8),
                  const Text(
                    'Gợi ý cảm xúc nhanh:',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in _quickTags)
                        ActionChip(
                          label: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _busy ? null : () => _addQuickTag(tag),
                          backgroundColor: AppColors.background,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. AUDIENCE & PRIVACY (Strava-style Selection Cards)
            const Text(
              'QUYỀN RIÊNG TƯ & ĐỐI TƯỢNG XEM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),

            // Option 1: Bạn bè (Friends)
            InkWell(
              onTap: _busy
                  ? null
                  : () => setState(() {
                        _audience = ActivityAudience.friends;
                        _preview = false;
                      }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _audience == ActivityAudience.friends
                        ? AppColors.primary
                        : AppColors.border,
                    width: _audience == ActivityAudience.friends ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_audience == ActivityAudience.friends
                                ? AppColors.primary
                                : AppColors.muted)
                            .withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 20,
                        color: _audience == ActivityAudience.friends
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bạn bè',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Chỉ bạn bè hai chiều trên SportXP mới xem được bài đăng',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _audience == ActivityAudience.friends
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _audience == ActivityAudience.friends
                          ? AppColors.primary
                          : AppColors.muted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Option 2: Chỉ mình tôi (Only Me)
            InkWell(
              onTap: _busy
                  ? null
                  : () => setState(() {
                        _audience = ActivityAudience.onlyMe;
                        _preview = false;
                      }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _audience == ActivityAudience.onlyMe
                        ? AppColors.primary
                        : AppColors.border,
                    width: _audience == ActivityAudience.onlyMe ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_audience == ActivityAudience.onlyMe
                                ? AppColors.primary
                                : AppColors.muted)
                            .withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 20,
                        color: _audience == ActivityAudience.onlyMe
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chỉ mình tôi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Lưu vào nhật ký cá nhân, người khác không thể xem',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _audience == ActivityAudience.onlyMe
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _audience == ActivityAudience.onlyMe
                          ? AppColors.primary
                          : AppColors.muted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            // Dropdown ẩn tương thích nếu có selector phụ
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 0,
                child: DropdownButton<ActivityAudience>(
                  value: _audience,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: ActivityAudience.onlyMe,
                      child: Text('Chỉ mình tôi'),
                    ),
                    DropdownMenuItem(
                      value: ActivityAudience.friends,
                      child: Text('Bạn bè'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            _audience = v!;
                            _preview = false;
                          }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. SPORTS FAIRPLAY & PRIVACY NOTES
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Minh bạch dữ liệu thể thao',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Trận chờ hoặc tranh chấp chưa được tính thắng/thua. Sau khi chốt, thống kê tự cập nhật; caption giữ nguyên.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Không tự gắn tên người chơi khác. Với buổi riêng tư, bạn bè ngoài buổi không thấy tên sân/tiêu đề gốc. Caption do bạn chủ động chia sẻ.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],

            const SizedBox(height: 24),

            // 5. LIVE PREVIEW BUTTON & CARD
            OutlinedButton.icon(
              onPressed: _busy ? null : () => setState(() => _preview = true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: _preview ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _preview ? Icons.check_circle : Icons.visibility_outlined,
                size: 18,
                color: _preview ? AppColors.primary : AppColors.text,
              ),
              label: Text(
                _preview ? 'Xem trước (Đã cập nhật)' : 'Xem trước',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _preview ? AppColors.primary : AppColors.text,
                ),
              ),
            ),

            if (_preview) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.feed_outlined, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'GIAO DIỆN HIỂN THỊ TRÊN BẢNG TIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ActivityCard(
                post: widget.post,
                caption: _caption.text.trim(),
                audience: _audience,
              ),
            ],

            const SizedBox(height: 16),

            // 6. ACTION BUTTONS (Lưu nháp / Đăng bài)
            OutlinedButton(
              onPressed: _busy ? null : () => _save('save'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Text(widget.post.isDraft ? 'Lưu nháp' : 'Lưu thay đổi'),
            ),

            if (widget.post.isDraft) ...[
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _busy || !_preview ? null : () => _save('publish'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _busy ? 'Đang đăng…' : 'Đăng bài',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],

            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}
