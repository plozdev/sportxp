import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../matchmaking/domain/court.dart';

/// Modal bottom sheet cho phép người dùng chọn sân thi đấu để xem BXH
class CourtPickerSheet extends StatelessWidget {
  const CourtPickerSheet({
    super.key,
    required this.courts,
    required this.selectedCourtId,
    required this.onSelectCourt,
  });

  final List<Court> courts;
  final String selectedCourtId;
  final ValueChanged<String> onSelectCourt;

  static void show(
    BuildContext context, {
    required List<Court> courts,
    required String selectedCourtId,
    required ValueChanged<String> onSelectCourt,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radius)),
      ),
      builder: (_) => CourtPickerSheet(
        courts: courts,
        selectedCourtId: selectedCourtId,
        onSelectCourt: onSelectCourt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'CHỌN SÂN XẾP HẠNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.muted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final court in courts) ...[
              _buildCourtOption(context, court),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourtOption(BuildContext context, Court court) {
    final isSelected = court.id == selectedCourtId;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelectCourt(court.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_tennis,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  if (court.distanceKm != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Cách bạn ~${court.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
