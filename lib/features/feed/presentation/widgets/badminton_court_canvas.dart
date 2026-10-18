import 'package:flutter/material.dart';

import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';

/// Graphic mô phỏng sân cầu lông thể thao mang phong cách bản đồ Strava.
class BadmintonCourtGraphic extends StatelessWidget {
  const BadmintonCourtGraphic({
    super.key,
    required this.post,
    this.height = 140,
  });

  final ActivityView post;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stats = post.totals;
    final isPersonal = post.kind == ActivityKind.personal;
    final wins = stats.wins ?? 0;
    final losses = stats.losses ?? 0;
    final winRate = stats.total > 0 ? ((wins / stats.total) * 100).round() : 0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1812), // Deep emerald court dark
            const Color(0xFF080C10),
            const Color(0xFF0B141C),
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
                width: 120,
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
                  color: Colors.black.withValues(alpha: 0.6),
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

            // Huy hiệu kết quả ở góc trên bên phải
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: wins > losses
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  isPersonal
                      ? (wins > losses && losses == 0
                          ? '🔥 BẤT BẠI'
                          : '$winRate% THẮNG')
                      : '${stats.confirmed}/${stats.total} ĐÃ XÁC NHẬN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: wins > losses ? AppColors.primary : AppColors.text,
                  ),
                ),
              ),
            ),

            // Trung tâm: Thông số hiệu suất nổi bật (Headline Strava Metric)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPersonal ? '${wins}W - ${losses}L' : '${stats.total} SET',
                    style: AppTokens.metric.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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
                  const SizedBox(height: 2),
                  Text(
                    isPersonal
                        ? 'TỔNG ${stats.total} TRẬN ĐÃ THI ĐẤU'
                        : 'BUỔI GIAO LƯU CLB',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            // Góc dưới bên trái: Địa điểm sân
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 11,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      post.courtName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'SPORTXP MATCH LOG',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.border,
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
