import 'package:flutter/material.dart';
import '../application/match_controller.dart';

class CreateMatchSheet extends StatefulWidget {
  const CreateMatchSheet({super.key, required this.controller});
  final MatchController controller;
  @override
  State<CreateMatchSheet> createState() => _CreateMatchSheetState();
}

class _CreateMatchSheetState extends State<CreateMatchSheet> {
  final _form = GlobalKey<FormState>();
  final _court = TextEditingController();
  final _hours = TextEditingController(text: '2');
  @override
  void dispose() {
    _court.dispose();
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tạo kèo đôi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _court,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Tên sân công cộng',
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Nhập tên sân ít nhất 3 ký tự.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bắt đầu sau (giờ)',
                ),
                validator: (value) {
                  final hours = int.tryParse(value ?? '');
                  return hours == null || hours < 1 || hours > 168
                      ? 'Nhập từ 1 đến 168 giờ.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              const Text('4 người • Dữ liệu chỉ lưu trong phiên demo này.'),
              if (widget.controller.error != null)
                Text(widget.controller.error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.controller.busy
                    ? null
                    : () async {
                        if (!_form.currentState!.validate()) return;
                        final success = await widget.controller.create(
                          _court.text,
                          DateTime.now().add(
                            Duration(hours: int.parse(_hours.text)),
                          ),
                        );
                        if (context.mounted && success) {
                          Navigator.pop(context, true);
                        }
                      },
                child: Text(widget.controller.busy ? 'ĐANG TẠO…' : 'TẠO KÈO'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
