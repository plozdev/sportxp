import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

enum _ResetStep { requestOtp, verifyAndNewPassword, success }

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({
    super.key,
    required this.client,
    this.initialEmail,
  });

  final SupabaseClient client;
  final String? initialEmail;

  static Future<bool?> show(
    BuildContext context, {
    required SupabaseClient client,
    String? initialEmail,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForgotPasswordSheet(
        client: client,
        initialEmail: initialEmail,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  _ResetStep _step = _ResetStep.requestOtp;

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyReset = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _busy = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendCountdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  String _mapAuthError(Object err) {
    if (err is AuthException) {
      final msg = err.message.toLowerCase();
      if (msg.contains('rate limit')) {
        return 'Bạn đã gửi quá số lần cho phép. Vui lòng đợi ít phút.';
      }
      if (msg.contains('token') || msg.contains('otp') || msg.contains('expired')) {
        return 'Mã xác thực không đúng hoặc đã hết hiệu lực.';
      }
      if (msg.contains('user not found')) {
        return 'Không tìm thấy tài khoản với địa chỉ email này.';
      }
      if (msg.contains('same password')) {
        return 'Mật khẩu mới không được trùng với mật khẩu cũ.';
      }
      return err.message;
    }
    return 'Đã xảy ra lỗi kết nối. Vui lòng kiểm tra lại mạng.';
  }

  // Bước 1: Gửi OTP đến email
  Future<void> _requestOtp() async {
    if (_busy || !_formKeyEmail.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    try {
      await widget.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _startCountdown();
      setState(() {
        _step = _ResetStep.verifyAndNewPassword;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Gửi lại mã OTP
  Future<void> _resendOtp() async {
    if (_busy || _resendCountdown > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    try {
      await widget.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text('Đã gửi lại mã xác thực mới đến email của bạn.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Bước 2: Xác thực mã OTP & cập nhật mật khẩu mới
  Future<void> _verifyAndResetPassword() async {
    if (_busy || !_formKeyReset.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text;

    try {
      // 1. Verify OTP recovery
      await widget.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      // 2. Cập nhật mật khẩu mới cho user
      await widget.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;
      setState(() {
        _step = _ResetStep.success;
      });
    } catch (e) {
      if (mounted) setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _ResetStep.requestOtp:
        return _buildRequestOtpView();
      case _ResetStep.verifyAndNewPassword:
        return _buildVerifyAndResetView();
      case _ResetStep.success:
        return _buildSuccessView();
    }
  }

  // ---------------------------------------------------------------------------
  // GIAO DIỆN BƯỚC 1: Yêu cầu gửi mã OTP
  // ---------------------------------------------------------------------------
  Widget _buildRequestOtpView() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        key: const ValueKey('step_request_otp'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khôi phục mật khẩu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Nhận mã OTP 6 số qua email đăng ký',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Nhập địa chỉ email tài khoản SportXP của bạn. Hệ thống sẽ gửi một mã số xác thực để bạn tạo mật khẩu mới.',
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _emailController,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Email của bạn',
              prefixIcon: const Icon(Icons.alternate_email, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (v) => !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                    .hasMatch(v?.trim() ?? '')
                ? 'Vui lòng nhập địa chỉ email hợp lệ.'
                : null,
            onFieldSubmitted: (_) => _requestOtp(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(_error!),
          ],

          const SizedBox(height: 24),

          FilledButton(
            onPressed: _busy ? null : _requestOtp,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppTokens.touchTarget),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text(
                    'GỬI MÃ XÁC THỰC',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GIAO DIỆN BƯỚC 2: Nhập OTP & Đặt mật khẩu mới
  // ---------------------------------------------------------------------------
  Widget _buildVerifyAndResetView() {
    return Form(
      key: _formKeyReset,
      child: Column(
        key: const ValueKey('step_verify_reset'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = _ResetStep.requestOtp;
                          _error = null;
                        }),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Đặt lại mật khẩu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
              children: [
                const TextSpan(text: 'Mã OTP 6 số đã được gửi đến '),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const TextSpan(text: '. Vui lòng kiểm tra hòm thư (kể cả mục Spam).'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 1. Ô nhập mã OTP 6 số
          TextFormField(
            controller: _otpController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              fontFeatures: [FontFeature.tabularFigures()],
              color: AppColors.primary,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: const TextStyle(
                letterSpacing: 8,
                color: AppColors.border,
              ),
              labelText: 'Mã xác thực OTP (6 chữ số)',
              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (v) => (v?.trim().length ?? 0) != 6
                ? 'Nhập đủ 6 số xác thực.'
                : null,
          ),
          const SizedBox(height: 14),

          // 2. Ô nhập mật khẩu mới
          TextFormField(
            controller: _newPasswordController,
            enabled: !_busy,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 6
                ? 'Mật khẩu mới cần ít nhất 6 ký tự.'
                : null,
          ),
          const SizedBox(height: 14),

          // 3. Ô xác nhận mật khẩu mới
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_busy,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Xác nhận lại mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            validator: (v) {
              if (v != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp.';
              }
              return null;
            },
          ),

          // Nút gửi lại mã & Đếm ngược
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_resendCountdown > 0)
                Text(
                  'Gửi lại mã sau ${_resendCountdown}s',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                )
              else
                TextButton(
                  onPressed: _busy ? null : _resendOtp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Gửi lại mã OTP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            _buildErrorBanner(_error!),
          ],

          const SizedBox(height: 20),

          FilledButton(
            onPressed: _busy ? null : _verifyAndResetPassword,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppTokens.touchTarget),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text(
                    'ĐẶT LẠI MẬT KHẨU',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GIAO DIỆN BƯỚC 3: Thành công
  // ---------------------------------------------------------------------------
  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('step_success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Đổi mật khẩu thành công!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu mới của bạn đã được cập nhật an toàn trên hệ thống. Bây giờ bạn có thể đăng nhập ngay.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppTokens.touchTarget),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'ĐĂNG NHẬP NGAY',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.loss.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.loss.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.loss),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.loss,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
