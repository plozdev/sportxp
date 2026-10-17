import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/court.dart';
import '../domain/create_room_draft.dart';

class CreateMatchSheet extends StatefulWidget {
  const CreateMatchSheet({
    super.key,
    required this.loadCourts,
    required this.onSubmit,
  });
  final Future<List<Court>> Function() loadCourts;
  final Future<void> Function(CreateRoomDraft) onSubmit;
  @override
  State<CreateMatchSheet> createState() => _CreateMatchSheetState();
}

class _CreateMatchSheetState extends State<CreateMatchSheet> {
  final _form = GlobalKey<FormState>();
  final _slots = TextEditingController(text: '4');
  late Future<List<Court>> _courts;
  String? _courtId, _error;
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 2));
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _courts = widget.loadCourts();
  }

  @override
  void dispose() {
    _slots.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt.isAfter(now) ? _startsAt : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time != null && mounted) {
      setState(
        () => _startsAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!_startsAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Vui lòng chọn thời gian trong tương lai.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        CreateRoomDraft(
          courtId: _courtId!,
          startsAt: _startsAt,
          maxSlots: int.parse(_slots.text),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa xác nhận được kèo. Kiểm tra danh sách trước khi gửi lại.',
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
                'Tạo kèo mới',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Court>>(
                future: _courts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('Không thể tải danh sách sân.'),
                        TextButton(
                          onPressed: () => setState(() {
                            _courtId = null;
                            _courts = widget.loadCourts();
                          }),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    );
                  }
                  final courts = snapshot.data!;
                  if (courts.isEmpty) {
                    return const Text('Chưa có sân để tạo kèo.');
                  }
                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Chọn sân'),
                    items: courts
                        .map(
                          (court) => DropdownMenuItem(
                            value: court.id,
                            child: Text(
                              court.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (id) => setState(() => _courtId = id),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn sân.' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  '${_startsAt.day}/${_startsAt.month}/${_startsAt.year} • ${TimeOfDay.fromDateTime(_startsAt).format(context)}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slots,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số chỗ tối đa (gồm bạn)',
                ),
                validator: (v) {
                  final slots = int.tryParse(v ?? '');
                  return slots == null || slots < 2 || slots > 100
                      ? 'Nhập từ 2 đến 100 chỗ.'
                      : null;
                },
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
                onPressed: _busy || _courtId == null ? null : _submit,
                child: Text(_busy ? 'ĐANG TẠO…' : 'TẠO KÈO'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
