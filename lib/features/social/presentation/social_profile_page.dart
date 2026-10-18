import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/social_repository.dart';
import '../domain/social_profile.dart';

class SocialProfilePage extends StatefulWidget {
  const SocialProfilePage({
    super.key,
    required this.publicId,
    required this.client,
  });
  final String publicId;
  final SupabaseClient client;
  @override
  State<SocialProfilePage> createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage> {
  late Future<SocialProfile?> _profile;
  bool _busy = false;
  SocialRepository get repo => SocialRepository(widget.client);
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = repo.profile(widget.publicId);
  }

  Future<void> _act(String action) async {
    if (_busy) return;
    final session = widget.client.auth.currentSession;
    if (session == null || session.isExpired) return;
    if (action == 'block' || action == 'unfriend') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(action == 'block' ? 'Chặn người này?' : 'Hủy kết bạn?'),
          content: const Text('Kết nối hiện tại sẽ được gỡ bỏ.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await repo.action(widget.publicId, action);
      if (mounted) setState(_load);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thể thực hiện. Hãy tải lại hồ sơ và thử lại sau.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('HỘ CHIẾU CẦU LÔNG'),
      actions: [
        IconButton(
          onPressed: _busy ? null : () => setState(_load),
          icon: const Icon(Icons.refresh),
          tooltip: 'Tải lại hồ sơ',
        ),
      ],
    ),
    body: AsyncPanel<SocialProfile?>(
      future: _profile,
      onRetry: () => setState(_load),
      builder: (p) {
        if (p == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Hồ sơ không khả dụng hoặc đang giới hạn quyền xem.'),
            ),
          );
        }
        final actions = switch (p.relationship) {
          'self' => <String, String>{},
          'friends' => {'unfriend': 'HỦY KẾT BẠN'},
          'incoming' => {'accept': 'CHẤP NHẬN', 'decline': 'TỪ CHỐI'},
          'outgoing' => {'cancel': 'HỦY LỜI MỜI'},
          'blocked' => {'unblock': 'BỎ CHẶN'},
          _ => {'request': 'KẾT BẠN'},
        };
        return PageContent(
          children: [
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (p.statsVisible) ...[
                    Text('${p.elo ?? '—'} ELO · ${p.tier ?? 'Chưa xếp hạng'}'),
                    Text('Chuỗi thắng: ${p.streak}'),
                  ] else if (p.relationship != 'blocked')
                    const Text(
                      'Chỉ bạn bè được xem chỉ số của người chơi này.',
                    ),
                  if (p.relationship == 'friends')
                    const Text('Bạn bè · Đã kết nối hai chiều'),
                  if (p.relationship == 'outgoing')
                    const Text('Đang chờ người nhận chấp nhận'),
                ],
              ),
            ),
            for (final entry in actions.entries)
              FilledButton(
                onPressed: _busy ? null : () => _act(entry.key),
                child: Text(entry.value),
              ),
            if (!['self', 'blocked'].contains(p.relationship))
              TextButton(
                onPressed: _busy ? null : () => _act('block'),
                child: const Text('Chặn người dùng'),
              ),
            if (_busy) const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    ),
  );
}
