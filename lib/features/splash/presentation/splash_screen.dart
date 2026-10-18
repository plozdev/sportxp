import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1800),
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

    // Hiệu ứng nhấp nháy neon điện tử thể thao (Cyber Athletic Neon Flicker)
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.05, end: 1.0), weight: 14),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.25), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.25, end: 1.0), weight: 14),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.55), weight: 8),
      TweenSequenceItem(tween: Tween<double>(begin: 0.55, end: 1.0), weight: 16),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
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
                // Vòng hào quang năng lượng phía sau logo (Ambient glow)
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: 0.18 * glow,
                          ),
                          blurRadius: 100 * glow,
                          spreadRadius: 30 * glow,
                        ),
                      ],
                    ),
                  ),
                ),

                // Nội dung chính giữa màn hình
                Center(
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Biểu tượng năng lượng thể thao
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.3 + 0.7 * glow,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35 * glow,
                                  ),
                                  blurRadius: 20 * glow,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 40,
                              color: Color.lerp(
                                AppColors.muted,
                                AppColors.primary,
                                glow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Chữ SPORTXP với hiệu ứng nhấp nháy phát sáng Neon
                          Text(
                            'SPORTXP',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6.0,
                              color: AppColors.text,
                              shadows: [
                                Shadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.8 * glow,
                                  ),
                                  blurRadius: 24 * glow,
                                ),
                                Shadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4 * glow,
                                  ),
                                  blurRadius: 48 * glow,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tagline thể thao
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
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
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Thanh nạp năng lượng tiến trình (Kinetic Loading Bar)
                          SizedBox(
                            width: 140,
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
