import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.client, this.startupError});
  final SupabaseClient? client;
  final String? startupError;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = false, _busy = false;
  bool _obscurePassword = true;
  String? _error, _message;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final client = widget.client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final response = _signUp
          ? await client.auth.signUp(
              email: _email.text.trim(),
              password: _password.text,
              data: {'display_name': _name.text.trim()},
            )
          : await client.auth.signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
      if (!mounted) return;
      if (response.session == null) {
        setState(() {
          _signUp = false;
          _message = 'Kiểm tra email để xác nhận tài khoản, sau đó đăng nhập.';
          _password.clear();
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể kết nối. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode(bool signUp) {
    if (_busy || _signUp == signUp) return;
    setState(() {
      _signUp = signUp;
      _error = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'SPORTXP',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: AutofillGroup(
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tiêu đề & Tagline căn giữa hoàn hảo với animation chuyển cảnh mượt
                          SizedBox(
                            width: double.infinity,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey<bool>(_signUp),
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _signUp
                                        ? 'Bắt đầu lên sân.'
                                        : 'Chào mừng trở lại.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _signUp
                                        ? 'Tạo tài khoản để ghi nhận set cầu và tính hạng Elo.'
                                        : 'Mỗi set cầu. Một bước tiến.',
                                    textAlign: TextAlign.center,
                                    style: AppTokens.label.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Thanh chuyển Tab Đăng nhập / Đăng ký hiện đại (Segmented Switcher)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleMode(false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !_signUp
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Đăng nhập',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                          color: !_signUp
                                              ? AppColors.background
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _toggleMode(true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOutCubic,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _signUp
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Đăng ký',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                          color: _signUp
                                              ? AppColors.background
                                              : AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Thông báo lỗi cấu hình Supabase nếu có
                          if (widget.client == null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.loss.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.loss.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: AppColors.loss,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.startupError ??
                                          'Chưa cấu hình kết nối Supabase.',
                                      style: const TextStyle(
                                        color: AppColors.loss,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Field "Tên hiển thị" được bọc animation mở rộng / thu gọn mượt mà
                          ClipRect(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: _signUp
                                  ? AnimatedOpacity(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      opacity: _signUp ? 1.0 : 0.0,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: TextFormField(
                                          controller: _name,
                                          enabled: !_busy,
                                          maxLength: 60,
                                          textCapitalization: TextCapitalization.words,
                                          decoration: InputDecoration(
                                            labelText: 'Tên hiển thị',
                                            // hintText: 'Nhập tên của bạn trên sân',
                                            prefixIcon: const Icon(
                                              Icons.badge_outlined,
                                              size: 20,
                                            ),
                                            counterText: '',
                                            filled: true,
                                            fillColor: AppColors.surface,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          validator: (v) => _signUp && (v?.trim().length ?? 0) < 2
                                              ? 'Nhập ít nhất 2 ký tự.'
                                              : null,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),

                          TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: 'Email',
                              // hintText: 'name@example.com',
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(v?.trim() ?? '')
                                ? 'Email không hợp lệ.'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscurePassword,
                            autofillHints: [
                              _signUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.muted,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => (v?.length ?? 0) < (_signUp ? 6 : 1)
                                ? 'Vui lòng nhập mật khẩu${_signUp ? ' ít nhất 6 ký tự' : ''}.'
                                : null,
                          ),

                          // Thông báo lỗi
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.loss.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.loss.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 18,
                                    color: AppColors.loss,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.loss,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Thông báo xác nhận email
                          if (_message != null)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.mark_email_read_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _message!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Nút Submit chính
                          SizedBox(
                            height: 50,
                            child: FilledButton(
                              onPressed: _busy || widget.client == null
                                  ? null
                                  : _submit,
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _busy
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.background,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('ĐANG XỬ LÝ…'),
                                      ],
                                    )
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Text(
                                        _signUp ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                                        key: ValueKey<bool>(_signUp),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Nút chuyển đổi phụ ở dưới (tương thích hoàn toàn với các test cũ)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleMode(!_signUp),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _signUp
                                    ? 'Đã có tài khoản? Đăng nhập'
                                    : 'Chưa có tài khoản? Đăng ký',
                                key: ValueKey<bool>(_signUp),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
