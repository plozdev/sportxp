import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/mock_room_repository.dart';

/// Modal bottom sheet hỗ trợ mô phỏng kết nối bạn bè và chặn trong chế độ thử nghiệm (Sandbox).
Future<void> showMockConnectionsSheet(
  BuildContext context,
  MockRoomRepository rooms, {
  VoidCallback? onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'KẾT NỐI BẠN BÈ GIẢ LẬP',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.muted,
                        letterSpacing: 1.0,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mô phỏng quan hệ bạn bè và chặn trong phiên thử nghiệm.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                for (final entry in rooms.people.entries.where(
                  (p) => p.key != rooms.actorId,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Bạn hai chiều',
                                style: TextStyle(fontSize: 13),
                              ),
                              value: rooms.areFriends(rooms.actorId, entry.key),
                              onChanged: rooms.isBlocked(rooms.actorId, entry.key)
                                  ? null
                                  : (value) {
                                      update(() => rooms.setMockFriend(entry.key, value));
                                      onChanged?.call();
                                    },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Chặn',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.loss,
                                ),
                              ),
                              value: rooms.isBlocked(rooms.actorId, entry.key),
                              onChanged: (value) {
                                update(() => rooms.setMockBlock(entry.key, value));
                                onChanged?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
