import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Các phương án thiết kế Splash Screen tìm thấy và phát triển từ tài nguyên dự án.
enum SplashDesignVariant {
  /// 1. CHÍNH THỨC (Master Brand Kit): Sân đấu đêm thể thao (Court Dark #09281E).
  /// Quy chuẩn theo tài liệu thương hiệu: `sportxp_logo_vertical_dark.png`.
  courtNight,

  /// 2. NỀN SÁNG CAO CẤP: Giữ Scaffold sáng nhưng sử dụng Squircle 3D Master Icon
  /// (`app_icon_master.png`) với bóng đổ đa tầng, tạo độ tương phản và chiều sâu vượt bậc.
  emeraldLight,

  /// 3. ĐĨA NGỌC LỤC BẢO: Nền sáng kết hợp Huy hiệu tròn Xanh Thẳm (#0D3D2A) viền kim loại,
  /// giúp tôn trọn vẹn biểu tượng XP Bạc Hà và Chóp Vàng Streak Gold.
  deepEmblemLight,

  /// 4. VECTOR LIGHT CHUẨN XANH: Sử dụng biểu tượng vector `symbol_light.png`
  /// (Chữ XP xanh đậm #134E3F tương phản cao trên nền huy hiệu trắng tinh khôi).
  vectorLight,
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2200),
    this.initialVariant = SplashDesignVariant.courtNight,
  });

  final VoidCallback onComplete;
  final Duration duration;
  final SplashDesignVariant initialVariant;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;

  late SplashDesignVariant _variant = widget.initialVariant;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Hiệu ứng phát quang năng lượng Emerald thể thao (Pulsing Glow)
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: 1.0), weight: 22),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.45), weight: 14),
      TweenSequenceItem(tween: Tween<double>(begin: 0.45, end: 1.0), weight: 22),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 42),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.95, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finish();
      }
    });

    _controller.forward();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  void _switchVariant(SplashDesignVariant next) {
    setState(() => _variant = next);
  }

  void _nextVariant() {
    final nextIndex = (_variant.index + 1) % SplashDesignVariant.values.length;
    _switchVariant(SplashDesignVariant.values[nextIndex]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _variant == SplashDesignVariant.courtNight;

    final backgroundColor = isDark
        ? const Color(0xFF09281E)
        : AppColors.background;

    final textColor = isDark ? Colors.white : AppColors.text;
    final subtextColor = isDark ? const Color(0xFF9ECEB5) : AppColors.muted;
    final progressTrackColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.border;
    final progressColor = isDark ? const Color(0xFFF59E0B) : AppColors.primary;

    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // 1. NỀN THỂ THAO: Gradient và Họa tiết vạch sân cầu lông chìm (Badminton Court Watermark)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const RadialGradient(
                          center: Alignment(0.0, -0.1),
                          radius: 1.15,
                          colors: [
                            Color(0xFF1B6D4C),
                            Color(0xFF134E3F),
                            Color(0xFF09281E),
                            Color(0xFF051912),
                          ],
                          stops: [0.0, 0.35, 0.75, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF2F7F3),
                            Color(0xFFE8F2EB),
                          ],
                        ),
                ),
                child: CustomPaint(
                  painter: _BadmintonCourtPainter(
                    color: isDark ? const Color(0xFF299A63) : AppColors.primary,
                    opacity: isDark ? 0.08 : 0.04,
                  ),
                ),
              ),
            ),

            // 2. VÒNG HÀO QUANG PHÁT QUÁNG TÂM SÂN (Ambient Spotlight)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) {
                final glow = _glowAnimation.value;
                return Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? const Color(0xFF299A63).withValues(alpha: 0.28 * glow)
                              : AppColors.primary.withValues(alpha: 0.12 * glow),
                          blurRadius: 100 * glow,
                          spreadRadius: 30 * glow,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 3. NỘI DUNG CHÍNH: Logo, Tên thương hiệu, Slogan & Thanh tải
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final fade = _fadeAnimation.value;
                  final scale = _scaleAnimation.value;
                  final glow = _glowAnimation.value;
                  final progress = _progressAnimation.value;

                  return Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Biểu tượng Logo theo từng phương án thiết kế
                          _buildLogoMark(_variant, glow),
                          const SizedBox(height: 24),

                          // Chữ thương hiệu SPORTXP
                          Text(
                            'SPORTXP',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5.0,
                              color: textColor,
                              shadows: isDark
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF299A63).withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Slogan quy chuẩn
                          _buildSloganPill(isDark),
                          const SizedBox(height: 42),

                          // Thanh Kinetic Progress Bar
                          SizedBox(
                            width: 140,
                            height: 3.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: progressTrackColor,
                                color: progressColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. NÚT CHUYỂN ĐỔI CHẾ ĐỘ THỬ NGHIỆM (Variant Switcher for Review)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: _nextVariant,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 13,
                        color: isDark ? const Color(0xFFDDF2E3) : AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _variantLabel(_variant),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFDDF2E3) : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. GỢI Ý CHẠM ĐỂ BẮT ĐẦU Ở ĐÁY MÀN HÌNH
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, _) => Opacity(
                  opacity: (_fadeAnimation.value * 0.75).clamp(0.0, 1.0),
                  child: Text(
                    'CHẠM ĐỂ BẮT ĐẦU',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: subtextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng Biểu tượng Logo theo từng phương án
  Widget _buildLogoMark(SplashDesignVariant variant, double glow) {
    switch (variant) {
      // 1. CHÍNH THỨC: Sân đấu đêm thể thao kết hợp Squircle 3D Master Icon
      case SplashDesignVariant.courtNight:
        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF299A63).withValues(alpha: 0.35 + 0.3 * glow),
                blurRadius: 36 * glow,
                spreadRadius: 4 * glow,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2 * glow),
                blurRadius: 20 * glow,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25 + 0.25 * glow),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/brand/app_icon_master.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackSymbol(isDark: true),
            ),
          ),
        );

      // 2. NỀN SÁNG: Squircle 3D Master Icon tương phản cao trên nền sáng
      case SplashDesignVariant.emeraldLight:
        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28 + 0.15 * glow),
                blurRadius: 32 * glow,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/brand/app_icon_master.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackSymbol(isDark: false),
            ),
          ),
        );

      // 3. ĐĨA NGỌC LỤC BẢO: Huy hiệu tròn màu xanh rừng thẳm (#0D3D2A) ôm lấy biểu tượng XP ánh bạc hà
      case SplashDesignVariant.deepEmblemLight:
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B6D4C),
                Color(0xFF134E3F),
                Color(0xFF09281E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25 + 0.2 * glow),
                blurRadius: 28 * glow,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.65), // Viền kim loại Streak Gold
              width: 2.2,
            ),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/brand/symbol.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackSymbol(isDark: true),
              ),
            ),
          ),
        );

      // 4. VECTOR XANH ĐẬM: Sử dụng biểu tượng vector `symbol_light.png`
      case SplashDesignVariant.vectorLight:
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16 + 0.15 * glow),
                blurRadius: 24 * glow,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/brand/symbol_light.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildFallbackSymbol(isDark: false),
              ),
            ),
          ),
        );
    }
  }

  /// Slogan Pill
  Widget _buildSloganPill(bool isDark) {
    if (isDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: const Text(
          'MỖI SET CẦU • MỘT BƯỚC TIẾN',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: Color(0xFFDDF2E3), // Mint Soft
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'MỖI SET CẦU • MỘT BƯỚC TIẾN',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildFallbackSymbol({required bool isDark}) {
    return Icon(
      Icons.sports_tennis,
      size: 48,
      color: isDark ? const Color(0xFFDDF2E3) : AppColors.primary,
    );
  }

  String _variantLabel(SplashDesignVariant v) {
    switch (v) {
      case SplashDesignVariant.courtNight:
        return 'Sân đấu đêm (Chính thức)';
      case SplashDesignVariant.emeraldLight:
        return 'Nền sáng 3D Squircle';
      case SplashDesignVariant.deepEmblemLight:
        return 'Đĩa ngọc lục bảo';
      case SplashDesignVariant.vectorLight:
        return 'Vector xanh đậm';
    }
  }
}

/// Vẽ họa tiết đường kẻ sân cầu lông thể thao (Badminton Court Lines)
/// Dựa trên bản thiết kế concept `ui/4.jpg` và `build_final_identity_assets.py`.
class _BadmintonCourtPainter extends CustomPainter {
  const _BadmintonCourtPainter({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final netPaint = Paint()
      ..color = color.withValues(alpha: opacity * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Chiều rộng sân tỉ lệ với màn hình
    final courtW = size.width * 0.85;
    final courtH = size.height * 0.78;
    final left = (size.width - courtW) / 2;
    final top = (size.height - courtH) / 2;
    final right = left + courtW;
    final bottom = top + courtH;
    final centerY = top + courtH / 2;
    final centerX = left + courtW / 2;

    // Đường biên đôi ngoài cùng
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(16),
      ),
      paint,
    );

    // Đường biên đơn (lùi vào 2 bên)
    final alleyW = courtW * 0.085;
    canvas.drawLine(Offset(left + alleyW, top), Offset(left + alleyW, bottom), paint);
    canvas.drawLine(Offset(right - alleyW, top), Offset(right - alleyW, bottom), paint);

    // Lưới giữa sân (Net line)
    canvas.drawLine(Offset(left, centerY), Offset(right, centerY), netPaint);

    // Vạch phát cầu ngắn (Short service line)
    final shortServiceDist = courtH * 0.15;
    canvas.drawLine(
      Offset(left, centerY - shortServiceDist),
      Offset(right, centerY - shortServiceDist),
      paint,
    );
    canvas.drawLine(
      Offset(left, centerY + shortServiceDist),
      Offset(right, centerY + shortServiceDist),
      paint,
    );

    // Vạch phát cầu dài đôi (Long service line doubles)
    final longServiceDist = courtH * 0.08;
    canvas.drawLine(
      Offset(left, top + longServiceDist),
      Offset(right, top + longServiceDist),
      paint,
    );
    canvas.drawLine(
      Offset(left, bottom - longServiceDist),
      Offset(right, bottom - longServiceDist),
      paint,
    );

    // Đường phân đôi sân (Center line) từ vạch phát cầu ngắn ra biên
    canvas.drawLine(
      Offset(centerX, top),
      Offset(centerX, centerY - shortServiceDist),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + shortServiceDist),
      Offset(centerX, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BadmintonCourtPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}
