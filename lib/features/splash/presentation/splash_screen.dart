import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 2000),
  });

  final VoidCallback onComplete;
  final Duration duration;

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
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Hiệu ứng phát quang năng lượng Emerald thể thao
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.1, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 12),
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 48),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = _glowAnimation.value;
            final fade = _fadeAnimation.value;
            final scale = _scaleAnimation.value;
            final progress = _progressAnimation.value;

            return Stack(
              children: [
                // Vòng hào quang xanh sân cầu Emerald (Ambient glow)
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.16 * glow,
                          ),
                          blurRadius: 90 * glow,
                          spreadRadius: 25 * glow,
                        ),
                      ],
                    ),
                  ),
                ),

                // Nội dung Logo & Slogan chính thức
                Center(
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Biểu tượng Logo SportXP chính thức (Shuttlecock + XP Gold)
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15 + 0.2 * glow,
                                  ),
                                  blurRadius: 24 * glow,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25 + 0.35 * glow,
                                ),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/brand/symbol.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.sports_tennis,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Chữ SPORTXP thương hiệu
                          const Text(
                            'SPORTXP',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5.0,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Slogan quy chuẩn
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border,
                              ),
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
                          ),
                          const SizedBox(height: 40),

                          // Thanh Kinetic Progress Bar
                          SizedBox(
                            width: 130,
                            height: 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.border,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Ghi chú chạm để tiếp tục ở đáy màn hình
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (fade * 0.7).clamp(0.0, 1.0),
                    child: const Text(
                      'CHẠM ĐỂ BẮT ĐẦU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
