import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/mock_room_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    final areas = {
      'Tất cả',
      ...MockRoomRepository.venues.map((v) => v.area),
    }.toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Bộ lọc tìm kèo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Đặt lại'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Area
                  const Text('Khu vực sân', style: AppTokens.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _area,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      for (final a in areas)
                        DropdownMenuItem(value: a, child: Text(a)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _area = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Distance
                  const Text(
                    'Khoảng cách (mô phỏng theo sân)',
                    style: AppTokens.label,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<double>(
                    initialValue: _radius,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 100,
                        child: Text('Mọi khoảng cách'),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Text('Trong bán kính 3 km (giả lập)'),
                      ),
                      DropdownMenuItem(
                        value: 5,
                        child: Text('Trong bán kính 5 km (giả lập)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _radius = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Skill / Elo Tier
                  const Text('Mức trình độ tối thiểu', style: AppTokens.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _skill,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Mọi trình độ'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Mọi trình độ'),
                      ),
                      for (final tier in RankTier.values)
                        DropdownMenuItem(
                          value: tier.minimumElo,
                          child: Text('${tier.label} (${tier.minimumElo}+ Elo)'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _skill = v),
                  ),
                  const SizedBox(height: 16),

                  // Max Fee
                  const Text('Mức phí tối đa', style: AppTokens.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _maxFee,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    hint: const Text('Mọi mức phí'),
                    items: const [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Mọi mức phí'),
                      ),
                      DropdownMenuItem(
                        value: 40000,
                        child: Text('Tối đa 40.000đ / người'),
                      ),
                      DropdownMenuItem(
                        value: 60000,
                        child: Text('Tối đa 60.000đ / người'),
                      ),
                      DropdownMenuItem(
                        value: 80000,
                        child: Text('Tối đa 80.000đ / người'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _maxFee = v),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  const Text('Ngày chơi', style: AppTokens.label),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      _date == null
                          ? 'Bất kỳ ngày nào'
                          : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: const TextStyle(color: AppColors.text),
                    ),
                    trailing: _date != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _date = null),
                          )
                        : const Icon(Icons.chevron_right, color: AppColors.muted),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date ?? now,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: now.add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Available Only
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Chỉ phòng còn chỗ',
                      style: TextStyle(color: AppColors.text),
                    ),
                    subtitle: const Text(
                      'Ẩn các kèo đã đủ người hoặc đóng tuyển',
                      style: AppTokens.label,
                    ),
                    value: _availableOnly,
                    onChanged: (v) => setState(() => _availableOnly = v),
                  ),
                ],
              ),
            ),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTokens.touchTarget),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ÁP DỤNG BỘ LỌC',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
