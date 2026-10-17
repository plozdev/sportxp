import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signUp = false, _busy = false;
  String? _error, _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final response = _signUp
          ? await widget.client.auth.signUp(
              email: _email.text.trim(),
              password: _password.text,
              data: {'display_name': _name.text.trim()},
            )
          : await widget.client.auth.signInWithPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
      if (!mounted) return;
      if (response.session != null) {
        Navigator.pop(context, true);
      } else {
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    tooltip: 'Đóng',
                    icon: const Icon(Icons.close),
                  ),
                ),
                Text(
                  _signUp ? 'Bắt đầu lên sân.' : 'Chào mừng trở lại.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mỗi set cầu. Một bước tiến.',
                  style: AppTokens.label,
                ),
                const SizedBox(height: 24),
                if (_signUp) ...[
                  TextFormField(
                    controller: _name,
                    enabled: !_busy,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiển thị',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Nhập ít nhất 2 ký tự.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      !RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(v?.trim() ?? '')
                      ? 'Email không hợp lệ.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  autofillHints: [
                    _signUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v?.length ?? 0) < (_signUp ? 6 : 1)
                      ? 'Vui lòng nhập mật khẩu${_signUp ? ' ít nhất 6 ký tự' : ''}.'
                      : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.loss),
                    ),
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_message!),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'ĐANG XỬ LÝ…'
                        : _signUp
                        ? 'ĐĂNG KÝ'
                        : 'ĐĂNG NHẬP',
                  ),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _signUp = !_signUp;
                          _error = null;
                          _message = null;
                        }),
                  child: Text(
                    _signUp
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
