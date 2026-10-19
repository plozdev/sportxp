import 'package:flutter/material.dart';

import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';

/// Graphic thể thao trực quan đa môn (Cầu lông, Chạy bộ, Workout bổ trợ)
/// thiết kế tinh giản, hiện đại chuẩn Strava.
class AthleticVisualGraphic extends StatelessWidget {
  const AthleticVisualGraphic({
    super.key,
    required this.post,
    this.height = 140,
  });

  final ActivityView post;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (post.sportType == 'running') {
      return _RunningRouteGraphic(post: post, height: height);
    }
    if (post.sportType == 'workout') {
      return _WorkoutIntensityGraphic(post: post, height: height);
    }
    return _BadmintonTacticalCourtGraphic(post: post, height: height);
  }
}

/// Tương thích ngược với các màn hình gọi BadmintonCourtGraphic
typedef BadmintonCourtGraphic = AthleticVisualGraphic;

/// 1. SÂN CẦU LÔNG CHIẾN THUẬT & KẾT QUẢ CÁC SET
class _BadmintonTacticalCourtGraphic extends StatelessWidget {
  const _BadmintonTacticalCourtGraphic({
    required this.post,
    required this.height,
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
    final scores = post.matchScores;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1914), // Court deep pine green
            Color(0xFF070C10),
            Color(0xFF09141B),
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

            // Điểm sáng trung tâm nhẹ nhàng
            Center(
              child: Container(
                width: 120,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Tag môn thể thao ở góc trên bên trái
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
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

            // Huy hiệu kết quả / tiến độ ở góc trên bên phải
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasPending
                        ? AppColors.streak.withValues(alpha: 0.4)
                        : (wins >= losses && wins > 0
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.border),
                  ),
                ),
                child: Text(
                  hasPending
                      ? 'CHỜ XÁC NHẬN'
                      : (isPersonal
                          ? '${wins}W - ${losses}L'
                          : '${stats.confirmed} TRẬN CHỐT'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasPending
                        ? AppColors.streak
                        : (wins >= losses && wins > 0
                            ? AppColors.primary
                            : AppColors.text),
                  ),
                ),
              ),
            ),

            // Tỉ số các set đấu ở đáy sân (tinh tế, hiện đại, thể hiện rõ diễn biến)
            if (scores.isNotEmpty)
              Positioned(
                bottom: 10,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < scores.length; i++) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'S${i + 1}: ',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                scores[i],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < scores.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 2. BẢN ĐỒ GPS CHẠY BỘ NGOÀI TRỜI CHUẨN STRAVA
class _RunningRouteGraphic extends StatelessWidget {
  const _RunningRouteGraphic({
    required this.post,
    required this.height,
  });

  final ActivityView post;
  final double height;

  @override
  Widget build(BuildContext context) {
    final distanceStr = post.distanceKm != null
        ? '${post.distanceKm!.toStringAsFixed(2)} km'
        : '5.20 km';
    final paceStr = post.pace != null ? '${post.pace} /km' : '5:26 /km';

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFC5200).withValues(alpha: 0.3), // Strava orange
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF140D09), // Strava subtle burnt amber dark
            Color(0xFF090A0C),
            Color(0xFF0A0F14),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Lưới bản đồ topo chìm + đường route GPS CustomPainter
            Positioned.fill(
              child: CustomPaint(
                painter: _GpsRoutePainter(),
              ),
            ),

            // Tag chạy bộ & GPS ở góc trên bên trái
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFC5200).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_run_rounded,
                      size: 13,
                      color: Color(0xFFFC5200),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CHẠY BỘ NGOÀI TRỜI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFFFC5200),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tag Strava GPS Sync góc trên phải
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 10, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'GPS TRACKED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thông số watermark góc dưới phải
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$distanceStr • $paceStr',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. BIỂU ĐỒ CƯỜNG ĐỘ TẬP THỂ LỰC & FOOTWORK
class _WorkoutIntensityGraphic extends StatelessWidget {
  const _WorkoutIntensityGraphic({
    required this.post,
    required this.height,
  });

  final ActivityView post;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
          width: 1,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF08141F),
            Color(0xFF070B10),
            Color(0xFF101924),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          children: [
            // Wave đồ thị nhịp tim CustomPainter
            Positioned.fill(
              child: CustomPaint(
                painter: _WorkoutWavePainter(),
              ),
            ),

            // Tag thể lực & footwork
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 12,
                      color: Color(0xFF00B4D8),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'TẬP THỂ LỰC & BỔ TRỢ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF00B4D8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tag vùng nhịp tim
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${post.avgHeartRate ?? 140} BPM TB',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.streak,
                  ),
                ),
              ),
            ),

            // Phụ đề vùng tập
            const Positioned(
              bottom: 10,
              left: 12,
              child: Text(
                'Zone 3 - Aerobic Power • Footwork 6 góc sân',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter vẽ hình học sân cầu lông tiêu chuẩn với line thanh thoát
class _BadmintonCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final courtPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(16, 14, size.width - 32, size.height - 28);

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
    final shortServiceDist = rect.width * 0.16;
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

/// Painter vẽ đường chạy GPS uốn lượn sắc sảo mang phong cách bản đồ Strava
class _GpsRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Vẽ lưới tọa độ mờ
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    for (double x = 20; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 15; y < size.height; y += 25) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Đường chạy GPS màu cam Strava với hiệu ứng glow
    const orangeColor = Color(0xFFFC5200);

    final glowPaint = Paint()
      ..color = orangeColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final start = Offset(size.width * 0.12, size.height * 0.72);
    path.moveTo(start.dx, start.dy);

    // Tạo đường chạy dạng loop thực tế
    path.cubicTo(
      size.width * 0.20,
      size.height * 0.35,
      size.width * 0.35,
      size.height * 0.25,
      size.width * 0.50,
      size.height * 0.40,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.55,
      size.width * 0.80,
      size.height * 0.28,
      size.width * 0.88,
      size.height * 0.60,
    );
    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.82,
      size.width * 0.68,
      size.height * 0.78,
    );
    final end = Offset(size.width * 0.45, size.height * 0.75);
    path.lineTo(end.dx, end.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, routePaint);

    // Điểm xuất phát (Green dot)
    final startPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(start, 5, startPaint);
    canvas.drawCircle(
      start,
      2,
      Paint()..color = Colors.white,
    );

    // Điểm kết thúc (Checkered / Orange dot)
    final endPaint = Paint()..color = orangeColor;
    canvas.drawCircle(end, 5, endPaint);
    canvas.drawCircle(
      end,
      2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter vẽ sóng cường độ nhịp tim bài tập
class _WorkoutWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF00B4D8).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00B4D8).withValues(alpha: 0.2),
          const Color(0xFF00B4D8).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    path.moveTo(0, size.height * 0.65);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * 0.65);

    final points = [
      0.10, 0.58,
      0.22, 0.42,
      0.35, 0.48,
      0.48, 0.32,
      0.62, 0.52,
      0.75, 0.38,
      0.88, 0.60,
      1.00, 0.50,
    ];

    for (int i = 0; i < points.length; i += 2) {
      final x = size.width * points[i];
      final y = size.height * points[i + 1];
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
