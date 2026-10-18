import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../domain/profile_link.dart';

class ScanProfilePage extends StatefulWidget {
  const ScanProfilePage({super.key});
  @override
  State<ScanProfilePage> createState() => _ScanProfilePageState();
}

class _ScanProfilePageState extends State<ScanProfilePage> {
  final _text = TextEditingController();
  bool _done = false;
  String? _error;
  void _open(String value) {
    if (_done) return;
    final id = ProfileLink.parse(value);
    if (id == null) {
      setState(() => _error = 'Đây không phải link hồ sơ SportXP hợp lệ.');
      return;
    }
    _done = true;
    Navigator.pop(context, id);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QUÉT HỘ CHIẾU')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)
          SizedBox(
            height: 300,
            child: MobileScanner(
              onDetect: (capture) {
                for (final code in capture.barcodes) {
                  if (code.rawValue != null) {
                    _open(code.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) => const Center(
                child: Text(
                  'Camera chưa khả dụng. Cho phép camera hoặc dán link bên dưới.',
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text('Quét mã chỉ mở hồ sơ. Bạn chủ động gửi lời mời kết bạn.'),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          decoration: InputDecoration(
            labelText: 'Hoặc dán link hồ sơ',
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => _open(_text.text),
          child: const Text('MỞ HỒ SƠ'),
        ),
      ],
    ),
  );
}
