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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.loss.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'ĐÃ HỦY',
          style: TextStyle(
            color: AppColors.loss,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'IN_PROGRESS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, size: 14, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'ĐANG DIỄN RA',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'ĐÃ KẾT THÚC',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'DRAFT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'BẢN NHÁP',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (availableSlots > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'CÒN $availableSlots CHỖ',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ĐỦ NGƯỜI',
        style: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRegistrationBadge() {
    if (room.isHost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: const Text(
          'HOST',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.myStatus == 'REGISTERED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        ),
        child: const Text(
          'ĐÃ THAM GIA',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (room.myStatus == 'WAITLIST') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.streak.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.streak.withValues(alpha: 0.6)),
        ),
        child: const Text(
          'DANH SÁCH CHỜ',
          style: TextStyle(
            color: AppColors.streak,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (room.myStatus == 'RECONFIRM') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.loss.withValues(alpha: 0.6)),
        ),
        child: const Text(
          'CẦN XÁC NHẬN LẠI',
          style: TextStyle(
            color: AppColors.loss,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = room.visibility == 'PRIVATE';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: room.myStatus == 'RECONFIRM'
              ? AppColors.loss.withValues(alpha: 0.5)
              : room.status == 'IN_PROGRESS'
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Slot Metric Badge & Status Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSlotBadge(),
                    const SizedBox(width: 8),
                    _buildRegistrationBadge(),
                    const Spacer(),
                    // Visibility tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
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
                            isPrivate ? 'Bạn bè' : 'Công khai',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  room.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Venue & Court Label
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.sports_tennis,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: room.courtName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            if (room.courtLabel.isNotEmpty) ...[
                              const TextSpan(
                                text: '  •  ',
                                style: TextStyle(color: AppColors.muted),
                              ),
                              TextSpan(
                                text: room.courtLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Address
                if (room.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          room.address,
                          style: AppTokens.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // Time Range
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        RoomUiFormatters.dateRange(room.startsAt, room.endsAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bento 3-Column Spec Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Elo/Skill
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TRÌNH ĐỘ', style: AppTokens.label),
                            const SizedBox(height: 2),
                            Text(
                              '${room.minElo}–${room.maxElo}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.text,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            Text(
                              RoomUiFormatters.skillRange(room.minElo, room.maxElo),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 34, color: AppColors.border),
                      // Fee
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CHI PHÍ', style: AppTokens.label),
                              const SizedBox(height: 2),
                              Text(
                                RoomUiFormatters.currency(room.fee),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.text,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Text(
                                '/người',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, height: 34, color: AppColors.border),
                      // Host
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('HOST', style: AppTokens.label),
                              const SizedBox(height: 2),
                              Text(
                                room.hostName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                room.hostPlays ? 'Có chơi' : 'Tổ chức',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Host booking confirmation notice if present
                if (room.bookingStatus == 'HOST_CONFIRMED') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Host đã khai báo đặt sân',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${room.reserved}/${room.capacity} đã vào',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Action Footer Button
                SizedBox(
                  width: double.infinity,
                  height: AppTokens.touchTarget,
                  child: room.myStatus == 'RECONFIRM'
                      ? FilledButton.icon(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.loss,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.warning_amber_rounded, size: 18),
                          label: const Text(
                            'CẦN XÁC NHẬN ĐIỀU KIỆN MỚI',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        )
                      : room.status == 'IN_PROGRESS'
                      ? FilledButton.icon(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text(
                            'VÀO PHÒNG ĐẤU',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'XEM CHI TIẾT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
