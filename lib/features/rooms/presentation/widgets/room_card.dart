import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/managed_room.dart';
import 'room_ui_formatters.dart';

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.isHighlight = false,
  });

  final ManagedRoom room;
  final VoidCallback onTap;
  final bool isHighlight;

  int get availableSlots =>
      (room.capacity - room.reserved).clamp(0, room.capacity);

  String get _hostShortName {
    final raw = room.hostName.trim();
    if (raw.isEmpty) return 'Host';
    final parts = raw.split('·').first.trim().split(RegExp(r'\s+'));
    return parts.last;
  }

  String get _hostInitial {
    final name = _hostShortName;
    return name.isNotEmpty ? name[0].toUpperCase() : 'H';
  }

  Widget _buildSlotBadge() {
    if (room.status == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'IN_PROGRESS') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_tennis, size: 11, color: AppColors.primary),
            SizedBox(width: 4),
            Text(
              'ĐANG ĐẤU',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (room.status == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'ĐÃ KẾT THÚC',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (room.status == 'DRAFT') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'BẢN NHÁP',
          style: TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (availableSlots > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_alt_outlined,
              size: 11,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'CÒN $availableSlots/${room.capacity} CHỖ',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ĐỦ NGƯỜI (${room.capacity}/${room.capacity})',
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.4,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildRegistrationBadge() {
    if (room.isHost) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
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
    final active = room.status == 'IN_PROGRESS' || isHighlight;
    final needsConfirm = room.myStatus == 'RECONFIRM';
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: needsConfirm
              ? AppColors.loss
              : active
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildSlotBadge(),
                  if (room.isHost || room.myStatus != null)
                    _buildRegistrationBadge(),
                  if (room.visibility == 'PRIVATE')
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        SizedBox(width: 4),
                        Text('Riêng tư · Vào bằng mã', style: AppTokens.label),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                room.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      RoomUiFormatters.dateRange(room.startsAt, room.endsAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      room.courtLabel.isNotEmpty
                          ? '${room.courtName} · ${room.courtLabel}'
                          : room.courtName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    RoomUiFormatters.skillRange(room.minElo, room.maxElo),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${RoomUiFormatters.currency(room.fee)} / người',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.mint,
                    child: Text(
                      _hostInitial,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Host · $_hostShortName',
                      style: AppTokens.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ],
              ),
              if (needsConfirm || room.status == 'IN_PROGRESS') ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: needsConfirm
                        ? AppColors.loss
                        : AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  icon: Icon(
                    needsConfirm
                        ? Icons.warning_amber_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    needsConfirm
                        ? 'CẦN XÁC NHẬN ĐIỀU KIỆN MỚI'
                        : 'VÀO PHÒNG ĐẤU',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
