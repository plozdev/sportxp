import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/match_draft.dart';

class RecordMatchSheet extends StatefulWidget {
  const RecordMatchSheet({super.key, required this.onSubmit});
  final Future<void> Function(MatchDraft) onSubmit;
  @override
  State<RecordMatchSheet> createState() => _RecordMatchSheetState();
}

class _RecordMatchSheetState extends State<RecordMatchSheet> {
  final _form = GlobalKey<FormState>();
  final _court = TextEditingController();
  final _teamA = TextEditingController();
  final _teamB = TextEditingController();
  final _score = TextEditingController();
  bool _win = true, _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final controller in [_court, _teamA, _teamB, _score]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        MatchDraft(
          courtName: _court.text.trim(),
          teamA: _teamA.text.trim(),
          teamB: _teamB.text.trim(),
          score: _score.text.trim().replaceAll('–', '-'),
          isWin: _win,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa xác nhận được kết quả. Kiểm tra bảng tin trước khi gửi lại để tránh ghi trùng.',
        );
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
                'Ghi nhận set cầu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final field in [
                (_court, 'Tên sân'),
                (_teamA, 'Tên đội A (đội của bạn)'),
                (_teamB, 'Tên đội B'),
              ]) ...[
                TextFormField(
                  controller: field.$1,
                  enabled: !_busy,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: field.$2),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Vui lòng nhập ${field.$2.toLowerCase()}.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _score,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Tỉ số',
                  hintText: '21-19 21-16',
                ),
                validator: MatchDraft.validateScore,
              ),
              const SizedBox(height: 16),
              const Text(
                'Kết quả của đội A (đội của bạn)',
                style: AppTokens.label,
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Thắng'),
                    icon: Icon(Icons.check),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Thua'),
                    icon: Icon(Icons.close),
                  ),
                ],
                selected: {_win},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _win = value.single),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.loss),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'ĐANG GHI NHẬN…' : 'LƯU KẾT QUẢ'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
