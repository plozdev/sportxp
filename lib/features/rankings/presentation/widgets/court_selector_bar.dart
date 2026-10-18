import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../matchmaking/domain/court.dart';

class CourtSelectorBar extends StatelessWidget {
  const CourtSelectorBar({
    super.key,
    required this.courts,
    required this.selectedCourtId,
    required this.onSelectCourt,
  });

  final List<Court> courts;
  final String? selectedCourtId;
  final ValueChanged<String?> onSelectCourt;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            label: 'Toàn khu vực',
            icon: Icons.public,
            isSelected: selectedCourtId == null,
            onTap: () => onSelectCourt(null),
          ),
          for (final court in courts) ...[
            const SizedBox(width: 8),
            _buildChip(
              label: court.name,
              icon: Icons.sports_tennis,
              distance: court.distanceKm != null
                  ? '${court.distanceKm!.toStringAsFixed(1)}km'
                  : null,
              isSelected: selectedCourtId == court.id,
              onTap: () => onSelectCourt(court.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    String? distance,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.text : AppColors.muted,
              ),
            ),
            if (distance != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
