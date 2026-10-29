import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/room_search.dart';
import '../../../rankings/domain/rank_tier.dart';

class RoomFilterState {
  RoomFilterState({
    this.area = 'Tất cả',
    this.radius = 100,
    this.date,
    this.skill,
    this.maxFee,
    this.availableOnly = false,
  });

  String area;
  double radius;
  DateTime? date;
  int? skill;
  int? maxFee;
  bool availableOnly;

  bool get hasActiveFilter =>
      area != 'Tất cả' ||
      radius != 100 ||
      date != null ||
      skill != null ||
      maxFee != null ||
      availableOnly;

  RoomSearch toSearch() => RoomSearch(
    area: area == 'Tất cả' ? null : area,
    maxDistanceKm: radius,
    date: date,
    skill: skill,
    maxFee: maxFee,
    availableOnly: availableOnly,
  );

  void reset() {
    area = 'Tất cả';
    radius = 100;
    date = null;
    skill = null;
    maxFee = null;
    availableOnly = false;
  }
}

class RoomFilterSheet extends StatefulWidget {
  const RoomFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final RoomFilterState initial;
  final ValueChanged<RoomFilterState> onApply;

  static Future<void> show({
    required BuildContext context,
    required RoomFilterState initial,
    required ValueChanged<RoomFilterState> onApply,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => RoomFilterSheet(
      initial: initial,
      onApply: onApply,
    ),
  );

  @override
  State<RoomFilterSheet> createState() => _RoomFilterSheetState();
}

class _RoomFilterSheetState extends State<RoomFilterSheet> {
  late String _area;
  late double _radius;
  late DateTime? _date;
  late int? _skill;
  late int? _maxFee;
  late bool _availableOnly;

  @override
  void initState() {
    super.initState();
    _area = widget.initial.area;
    _radius = widget.initial.radius;
    _date = widget.initial.date;
    _skill = widget.initial.skill;
    _maxFee = widget.initial.maxFee;
    _availableOnly = widget.initial.availableOnly;
  }

  int get _activeCount {
    int count = 0;
    if (_area != 'Tất cả') count++;
    if (_radius != 100) count++;
    if (_skill != null) count++;
    if (_maxFee != null) count++;
    if (_date != null) count++;
    if (_availableOnly) count++;
    return count;
  }

  bool get _hasActiveFilters => _activeCount > 0;

  void _reset() {
    setState(() {
      _area = 'Tất cả';
      _radius = 100;
      _date = null;
      _skill = null;
      _maxFee = null;
      _availableOnly = false;
    });
  }

  void _apply() {
    final state = RoomFilterState(
      area: _area,
      radius: _radius,
      date: _date,
      skill: _skill,
      maxFee: _maxFee,
      availableOnly: _availableOnly,
    );
    widget.onApply(state);
    Navigator.pop(context);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceChip<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onSelected,
    IconData? icon,
    String? badge,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.text,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = const [
      'Tất cả',
      'Phú Nhuận',
      'Bình Thạnh',
      'Thủ Đức',
      'Quận 1',
      'Quận 3',
      'Quận 7',
      'Quận 10',
      'Tân Bình',
      'Gò Vấp',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final isTodaySelected = _isSameDay(_date, today);
    final isTomorrowSelected = _isSameDay(_date, tomorrow);
    final isCustomDateSelected =
        _date != null && !isTodaySelected && !isTomorrowSelected;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Header: Title, Active Filter Badge & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
              child: Row(
                children: [
                  const Text(
                    'Bộ lọc tìm kèo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (_activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '$_activeCount đang chọn',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.muted,
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // 1. KHU VỰC SÂN
                  _buildSectionHeader(
                    icon: Icons.location_on_outlined,
                    title: 'KHU VỰC SÂN',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in areas)
                        _buildChoiceChip<String>(
                          label: a,
                          value: a,
                          groupValue: _area,
                          onSelected: (val) => setState(() => _area = val),
                          icon: a == 'Tất cả'
                              ? Icons.public_rounded
                              : Icons.place_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. KHOẢNG CÁCH (BÁN KÍNH)
                  _buildSectionHeader(
                    icon: Icons.near_me_outlined,
                    title: 'BÁN KÍNH TỐI ĐA',
                    subtitle: '(mô phỏng theo sân)',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip<double>(
                        label: 'Mọi khoảng cách',
                        value: 100,
                        groupValue: _radius,
                        onSelected: (val) => setState(() => _radius = val),
                      ),
                      _buildChoiceChip<double>(
                        label: 'Trong 3 km',
                        value: 3,
                        groupValue: _radius,
                        onSelected: (val) => setState(() => _radius = val),
                      ),
                      _buildChoiceChip<double>(
                        label: 'Trong 5 km',
                        value: 5,
                        groupValue: _radius,
                        onSelected: (val) => setState(() => _radius = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. MỨC TRÌNH ĐỘ TỐI THIỂU
                  _buildSectionHeader(
                    icon: Icons.military_tech_outlined,
                    title: 'MỨC TRÌNH ĐỘ TỐI THIỂU',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip<int?>(
                        label: 'Mọi trình độ',
                        value: null,
                        groupValue: _skill,
                        onSelected: (val) => setState(() => _skill = val),
                      ),
                      for (final tier in RankTier.values)
                        _buildChoiceChip<int?>(
                          label: tier.label,
                          badge: '${tier.minimumElo}+ Elo',
                          value: tier.minimumElo,
                          groupValue: _skill,
                          onSelected: (val) => setState(() => _skill = val),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. MỨC PHÍ TỐI ĐA
                  _buildSectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'MỨC PHÍ TỐI ĐA',
                    subtitle: '(/người)',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip<int?>(
                        label: 'Mọi mức phí',
                        value: null,
                        groupValue: _maxFee,
                        onSelected: (val) => setState(() => _maxFee = val),
                      ),
                      _buildChoiceChip<int?>(
                        label: '≤ 40.000đ',
                        value: 40000,
                        groupValue: _maxFee,
                        onSelected: (val) => setState(() => _maxFee = val),
                      ),
                      _buildChoiceChip<int?>(
                        label: '≤ 60.000đ',
                        value: 60000,
                        groupValue: _maxFee,
                        onSelected: (val) => setState(() => _maxFee = val),
                      ),
                      _buildChoiceChip<int?>(
                        label: '≤ 80.000đ',
                        value: 80000,
                        groupValue: _maxFee,
                        onSelected: (val) => setState(() => _maxFee = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. NGÀY CHƠI
                  _buildSectionHeader(
                    icon: Icons.calendar_today_outlined,
                    title: 'NGÀY CHƠI',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Bất kỳ
                      _buildChoiceChip<bool>(
                        label: 'Bất kỳ ngày nào',
                        value: true,
                        groupValue: _date == null,
                        onSelected: (_) => setState(() => _date = null),
                        icon: Icons.calendar_view_day_outlined,
                      ),
                      // Hôm nay
                      _buildChoiceChip<bool>(
                        label: 'Hôm nay',
                        value: true,
                        groupValue: isTodaySelected,
                        onSelected: (_) => setState(() => _date = today),
                      ),
                      // Ngày mai
                      _buildChoiceChip<bool>(
                        label: 'Ngày mai',
                        value: true,
                        groupValue: isTomorrowSelected,
                        onSelected: (_) => setState(() => _date = tomorrow),
                      ),
                      // Chọn ngày cụ thể
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date ?? now,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isCustomDateSelected
                                ? AppColors.primary.withValues(alpha: 0.16)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCustomDateSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isCustomDateSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_calendar_outlined,
                                size: 13,
                                color: isCustomDateSelected
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isCustomDateSelected
                                    ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                    : 'Chọn ngày…',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCustomDateSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isCustomDateSelected
                                      ? AppColors.primary
                                      : AppColors.text,
                                ),
                              ),
                              if (isCustomDateSelected) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setState(() => _date = null),
                                  child: const Icon(
                                    Icons.close,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. CHỈ PHÒNG CÒN CHỖ (CONTAINER CARD CHỐNG CẮT CHỮ)
                  _buildSectionHeader(
                    icon: Icons.event_seat_outlined,
                    title: 'TÌNH TRẠNG CHỖ',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _availableOnly
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.how_to_reg_outlined,
                          color: _availableOnly
                              ? AppColors.primary
                              : AppColors.muted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Chỉ phòng còn chỗ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ẩn các kèo đã đủ người hoặc đóng tuyển',
                                style: AppTokens.label,
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _availableOnly,
                          activeTrackColor: AppColors.primary,
                          onChanged: (v) => setState(() => _availableOnly = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Action Bar (Đặt lại + Áp dụng)
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _hasActiveFilters ? _reset : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(100, 48),
                      side: BorderSide(
                        color: _hasActiveFilters
                            ? AppColors.border
                            : AppColors.border.withValues(alpha: 0.4),
                      ),
                      foregroundColor:
                          _hasActiveFilters ? AppColors.text : AppColors.muted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text(
                      'Đặt lại',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _activeCount > 0
                            ? 'ÁP DỤNG ($_activeCount BỘ LỌC)'
                            : 'ÁP DỤNG BỘ LỌC',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
