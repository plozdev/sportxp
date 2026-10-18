import 'package:flutter/material.dart';

import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';

/// Graphic mô phỏng sân cầu lông thể thao mang phong cách Strava.
/// Tinh gọn, chỉ hiển thị hình sân vector cùng một thông số thành tích chuẩn xác,
/// tránh lặp lại tên sân và tránh nhãn gây hiểu nhầm khi còn trận chờ xác nhận.
class BadmintonCourtGraphic extends StatelessWidget {
  const BadmintonCourtGraphic({
    super.key,
    required this.post,
    this.height = 130,
  });

  final ActivityView post;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stats = post.totals;
    final isPersonal = post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;
    final hasPending = stats.pending > 0;
    final isAllConfirmed = stats.confirmed == stats.total && stats.total > 0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1812), // Deep emerald court dark
            Color(0xFF080C10),
            Color(0xFF0B141C),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Sân cầu lông vector vẽ bằng CustomPainter
            Positioned.fill(
              child: CustomPaint(
                painter: _BadmintonCourtPainter(),
              ),
            ),

            // Hiệu ứng ánh sáng Neon ở giữa sân
            Center(
              child: Container(
                width: 130,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Tag môn thể thao ở góc trên bên trái
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_tennis_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPersonal ? 'CẦU LÔNG ĐÔI' : 'TỔNG KẾT BUỔI CHƠI',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Huy hiệu tiến độ xác nhận ở góc trên bên phải
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasPending
                        ? AppColors.streak.withValues(alpha: 0.4)
                        : (isAllConfirmed
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.border),
                  ),
                ),
                child: Text(
                  hasPending
                      ? 'CHỜ XÁC NHẬN'
                      : (isAllConfirmed && isPersonal && wins > 0 && losses == 0
                          ? 'TOÀN THẮNG'
                          : 'ĐÃ CHỐT'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: hasPending
                        ? AppColors.streak
                        : (isAllConfirmed && isPersonal && wins > 0 && losses == 0
                            ? AppColors.primary
                            : AppColors.text),
                  ),
                ),
              ),
            ),

            // Trung tâm: Thành tích thể hiện rõ ràng bằng tiếng Việt
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPersonal
                        ? '$wins thắng · $losses thua'
                        : '${stats.confirmed}/${stats.total} trận chốt',
                    style: AppTokens.metric.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: isPersonal && wins >= losses
                          ? AppColors.primary
                          : AppColors.text,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPersonal
                        ? (hasPending
                            ? 'đã xác nhận · còn ${stats.pending} trận chờ'
                            : 'tổng ${stats.total} trận toàn buổi')
                        : 'buổi chơi hoàn tất',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasPending ? AppColors.streak : AppColors.muted,
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

/// Painter vẽ hình học sân cầu lông tiêu chuẩn với hiệu ứng đường line phát sáng
class _BadmintonCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final courtPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(16, 12, size.width - 32, size.height - 24);

    // Đường biên ngoài sân
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      courtPaint,
    );

    // Lưới giữa sân
    final netX = rect.center.dx;
    canvas.drawLine(
      Offset(netX, rect.top),
      Offset(netX, rect.bottom),
      netPaint,
    );

    // Đường giao cầu ngắn (Short service lines) ở 2 bên lưới
    final shortServiceDist = rect.width * 0.15;
    canvas.drawLine(
      Offset(netX - shortServiceDist, rect.top),
      Offset(netX - shortServiceDist, rect.bottom),
      courtPaint,
    );
    canvas.drawLine(
      Offset(netX + shortServiceDist, rect.top),
      Offset(netX + shortServiceDist, rect.bottom),
      courtPaint,
    );

    // Đường trung tâm chia đôi sân giao cầu (Center line)
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(netX - shortServiceDist, rect.center.dy),
      courtPaint,
    );
    canvas.drawLine(
      Offset(netX + shortServiceDist, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      courtPaint,
    );

    // Đường biên giao cầu dài đánh đôi (Long service line for doubles)
    final doubleBackDist = rect.width * 0.08;
    canvas.drawLine(
      Offset(rect.left + doubleBackDist, rect.top),
      Offset(rect.left + doubleBackDist, rect.bottom),
      courtPaint,
    );
    canvas.drawLine(
      Offset(rect.right - doubleBackDist, rect.top),
      Offset(rect.right - doubleBackDist, rect.bottom),
      courtPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
