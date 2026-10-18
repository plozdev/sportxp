import 'package:flutter/material.dart';

import '../../../shared/widgets/bento_card.dart';
import '../data/social_repository.dart';
import '../domain/social_profile.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({
    super.key,
    required this.repository,
    required this.onOpen,
  });
  final SocialRepository repository;
  final Future<void> Function(String) onOpen;
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  String _kind = 'friends';
  List<SocialProfile> _items = [];
  bool _busy = true, _more = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    final kind = _kind;
    setState(() {
      _busy = true;
      _error = null;
      if (reset) {
        _items = [];
        _more = true;
      }
    });
    try {
      final rows = await widget.repository.connections(
        kind,
        offset: _items.length,
      );
      if (mounted && kind == _kind) {
        setState(() {
          _items.addAll(rows);
          _more = rows.length == 50;
        });
      }
    } catch (_) {
      if (mounted && kind == _kind) {
        setState(() => _error = 'Chưa tải được kết nối. Vui lòng thử lại.');
      }
    } finally {
      if (mounted && kind == _kind) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KẾT NỐI CỦA BẠN')),
    body: PageContent(
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final e in const {
              'friends': 'Bạn bè',
              'incoming': 'Lời mời đến',
              'outgoing': 'Đã gửi',
              'blocked': 'Đã chặn',
            }.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _kind == e.key,
                onSelected: _busy
                    ? null
                    : (_) {
                        _kind = e.key;
                        _load(reset: true);
                      },
              ),
          ],
        ),
        if (!_busy && _items.isEmpty && _error == null)
          const BentoCard(
            child: Text(
              'Chưa có kết nối ở đây. Chia sẻ hoặc quét mã hộ chiếu để tìm bạn.',
            ),
          ),
        for (final p in _items)
          BentoCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: Text(
                p.statsVisible
                    ? '${p.elo ?? '—'} ELO · ${p.tier ?? ''}'
                    : 'Hồ sơ giới hạn quyền xem',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await widget.onOpen(p.publicId);
                if (mounted) _load(reset: true);
              },
            ),
          ),
        if (_error != null) Text(_error!),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (!_busy)
          TextButton(
            onPressed: () => _load(reset: _error != null || !_more),
            child: Text(_more && _error == null ? 'Tải thêm' : 'Tải lại'),
          ),
      ],
    ),
  );
}
