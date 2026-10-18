import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/mock_room_repository.dart';
import '../domain/room_repository.dart';

class MockRoomControls extends StatefulWidget {
  const MockRoomControls({
    super.key,
    required this.repository,
    required this.onChanged,
    this.allowReset = false,
  });

  final RoomRepository repository;
  final VoidCallback onChanged;
  final bool allowReset;

  @override
  State<MockRoomControls> createState() => _MockRoomControlsState();
}

class _MockRoomControlsState extends State<MockRoomControls> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    if (repo is! MockRoomRepository) return const SizedBox.shrink();

    final currentActorName = repo.people[repo.actorId] ?? repo.actorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: AppColors.streak,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MÔ PHỎNG DỮ LIỆU MVP (SANDBOX)',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.streak,
                          ),
                        ),
                        Text(
                          'Đang đóng vai: $currentActorName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.tune,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Chọn vai diễn trong phòng:', style: AppTokens.label),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: repo.actorId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: [
                      for (final p in repo.people.entries)
                        DropdownMenuItem(value: p.key, child: Text(p.value)),
                    ],
                    onChanged: (id) {
                      if (id != null) {
                        repo.selectActor(id);
                        widget.onChanged();
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Linh là bạn hai chiều của mọi vai. Dữ liệu chỉ lưu trong RAM sandbox, không ảnh hưởng Supabase thật.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  if (widget.allowReset) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        repo.reset();
                        widget.onChanged();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.muted,
                      ),
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset dữ liệu mô phỏng'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
