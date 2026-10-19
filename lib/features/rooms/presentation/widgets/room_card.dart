import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/managed_room.dart';
import 'room_ui_formatters.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  final ManagedRoom room;
  final VoidCallback onTap;

  int get availableSlots => (room.capacity - room.reserved).clamp(0, room.capacity);

  Widget _buildSlotBadge() {
    if (room.status == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'ĐÃ HỦY',
          style: TextStyle(
            color: AppColors.loss,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'IN_PROGRESS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, size: 12, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'ĐANG ĐẤU',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'ĐÃ KẾT THÚC',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'DRAFT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'BẢN NHÁP',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (availableSlots > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'CÒN $availableSlots/${room.capacity} CHỖ',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ĐỦ NGƯỜI (${room.capacity}/${room.capacity})',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildRegistrationBadge() {
    if (room.isHost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: const Text(
          'HOST',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.myStatus == 'REGISTERED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: const Text(
          'ĐÃ VÀO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (room.myStatus == 'WAITLIST') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.streak.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.streak.withValues(alpha: 0.6)),
        ),
        child: const Text(
          'CHỜ CHỖ',
          style: TextStyle(
            color: AppColors.streak,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (room.myStatus == 'RECONFIRM') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.loss.withValues(alpha: 0.6)),
        ),
        child: const Text(
          'CẦN XÁC NHẬN',
          style: TextStyle(
            color: AppColors.loss,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = room.visibility == 'PRIVATE';
    final hasAction = room.myStatus == 'RECONFIRM' || room.status == 'IN_PROGRESS';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: room.myStatus == 'RECONFIRM'
              ? AppColors.loss.withValues(alpha: 0.6)
              : room.status == 'IN_PROGRESS'
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: room.myStatus == 'RECONFIRM' || room.status == 'IN_PROGRESS' ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: HEADER ROW (Mode, Room Code, Registration & Slot Badge)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mode & Code Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPrivate
                            ? AppColors.streak.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPrivate
                              ? AppColors.streak.withValues(alpha: 0.4)
                              : AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                            size: 12,
                            color: isPrivate ? AppColors.streak : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPrivate ? 'PRIVATE' : 'PUBLIC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isPrivate ? AppColors.streak : AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.roomCode,
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
                    if (room.isHost || room.myStatus != null) ...[
                      const SizedBox(width: 6),
                      _buildRegistrationBadge(),
                    ],
                    const Spacer(),
                    _buildSlotBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // SECTION 2: MATCH TITLE & SCHEDULE
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  RoomUiFormatters.dateRange(room.startsAt, room.endsAt),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Venue
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  room.courtLabel.isNotEmpty
                                      ? '${room.courtName} • ${room.courtLabel}'
                                      : room.courtName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500,
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
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SECTION 3: KEY SPECS INLINE STRIP (Compact & Clean)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                RoomUiFormatters.skillRange(room.minElo, room.maxElo),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 16, color: AppColors.border),
                      // Fee
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 14,
                                color: AppColors.streak,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  RoomUiFormatters.currency(room.fee),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 16, color: AppColors.border),
                      // Host
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  room.hostName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // SECTION 4: CONDITIONAL ACTION BUTTON (Only if action required)
                if (hasAction) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: room.myStatus == 'RECONFIRM'
                        ? FilledButton.icon(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.loss,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.warning_amber_rounded, size: 16),
                            label: const Text(
                              'CẦN XÁC NHẬN ĐIỀU KIỆN MỚI',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text(
                              'VÀO PHÒNG ĐẤU',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
