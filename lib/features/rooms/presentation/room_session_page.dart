import 'package:flutter/material.dart';

import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import 'mock_room_controls.dart';

class RoomSessionPage extends StatefulWidget {
  const RoomSessionPage({
    super.key,
    required this.repository,
    required this.roomId,
  });
  final RoomSessionRepository repository;
  final String roomId;
  @override
  State<RoomSessionPage> createState() => _RoomSessionPageState();
}

class _RoomSessionPageState extends State<RoomSessionPage> {
  late Future<(ManagedRoom?, Map<String, dynamic>)> _data;
  bool _busy = false;
  String? _error;
  RoomCommand? _pending;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _data = (() async => (
      await widget.repository.get(widget.roomId),
      await widget.repository.session(widget.roomId),
    ))();
  }

  Future<void> _send(String action, Map<String, dynamic> payload) async {
    if (_busy) return;
    final command = RoomCommand(
      action,
      roomId: widget.roomId,
      payload: payload,
    );
    _pending = command;
    await _submit();
  }

  Future<void> _submit() async {
    if (_busy || _pending == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.execute(_pending!);
      _pending = null;
      if (mounted) setState(_load);
    } catch (e) {
      if (mounted) setState(() => _error = roomFailure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _reason(String title) async {
    final input = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: input,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Lý do / ghi chú'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(context, input.text.trim());
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    // Dialog's exit animation still owns its text field until the next frame.
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => input.dispose());
    }
    return value;
  }

  Future<void> _matchForm(
    ManagedRoom room, [
    Map<String, dynamic>? existing,
  ]) async {
    final players = room.members
        .where((m) => m['status'] == 'REGISTERED' && m['is_playing'] == true)
        .toList();
    final score = TextEditingController(
      text: existing?['score'] as String? ?? '21-19',
    );
    var doubles = (existing?['team_a'] as List?)?.length == 2;
    final choices = <String?>[null, null, null, null];
    if (existing != null) {
      final a = List<String>.from(existing['team_a'] as List),
          b = List<String>.from(existing['team_b'] as List);
      choices[0] = a[0];
      choices[1] = b[0];
      if (doubles) {
        choices[2] = a[1];
        choices[3] = b[1];
      }
    }
    var winner = existing?['winner'] as String? ?? 'A';
    String? error;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            existing == null
                ? 'Ghi trận mới'
                : 'Sửa kết quả và xin xác nhận lại',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Đánh đôi'),
                  value: doubles,
                  onChanged: (v) => update(() => doubles = v),
                ),
                for (final index in doubles ? [0, 2, 1, 3] : [0, 1])
                  DropdownButtonFormField<String>(
                    key: ValueKey('$index-$doubles'),
                    initialValue: choices[index],
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                          'Đội ${index.isEven ? 'A' : 'B'} · người ${index < 2 ? 1 : 2}',
                    ),
                    items: [
                      for (final p in players)
                        DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(p['name'] as String),
                        ),
                    ],
                    onChanged: (v) => choices[index] = v,
                  ),
                TextField(
                  controller: score,
                  decoration: const InputDecoration(
                    labelText: 'Tỉ số (A-B): 21-19 21-16',
                  ),
                ),
                DropdownButton<String>(
                  value: winner,
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('Đội A thắng')),
                    DropdownMenuItem(value: 'B', child: Text('Đội B thắng')),
                  ],
                  onChanged: (v) => update(() => winner = v!),
                ),
                if (error != null) Text(error!),
                const Text(
                  'Cần một người bên đối thủ xác nhận. Chưa tính Elo.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () {
                final indices = doubles ? [0, 2, 1, 3] : [0, 1];
                if (indices.any((i) => choices[i] == null) ||
                    indices.map((i) => choices[i]).toSet().length !=
                        indices.length) {
                  update(() => error = 'Chọn đủ người, không trùng nhau.');
                  return;
                }
                Navigator.pop(context, <String, dynamic>{
                  'team_a': [choices[0], if (doubles) choices[2]],
                  'team_b': [choices[1], if (doubles) choices[3]],
                  'score': score.text.trim(),
                  'winner': winner,
                  if (existing != null) ...{
                    'match_id': existing['id'],
                    'expected_version': existing['version'],
                  },
                });
              },
              child: const Text('Gửi kết quả'),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => score.dispose());
    }
    if (payload != null && mounted) {
      await _send(existing == null ? 'match_create' : 'match_edit', payload);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Trận đấu & điểm danh'),
      actions: [
        IconButton(
          onPressed: _busy ? null : () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AsyncPanel<(ManagedRoom?, Map<String, dynamic>)>(
      future: _data,
      onRetry: () => setState(_load),
      builder: (data) {
        final room = data.$1, session = data.$2;
        if (room == null) {
          return const Center(child: Text('Không có quyền xem.'));
        }
        String names(dynamic ids) => (ids as List)
            .map((id) => room.members.firstWhere((m) => m['id'] == id)['name'])
            .join(' + ');
        return PageContent(
          children: [
            MockRoomControls(
              repository: widget.repository,
              onChanged: () {
                _pending = null;
                _error = null;
                setState(_load);
              },
            ),
            Text(
              '${room.title} · ${room.statusLabel}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text(
              'Kết thúc buổi không tự xác nhận trận hoặc điểm danh. Trận chờ/tranh chấp vẫn cần xử lý. Elo và Trust thật giữ nguyên.',
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              TextButton(
                onPressed: _busy ? null : _submit,
                child: const Text('Gửi lại cùng yêu cầu'),
              ),
            ],
            if (room.status == 'IN_PROGRESS')
              FilledButton(
                onPressed: _busy ? null : () => _matchForm(room),
                child: const Text('+ Ghi trận đơn / đôi'),
              ),
            for (final m
                in (session['matches'] as List).cast<Map<String, dynamic>>())
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${names(m['team_a'])} — ${names(m['team_b'])}'),
                    Text('${m['score']} · đội ${m['winner']} thắng'),
                    Text(
                      '${m['status']} · bản ${m['version']} · Elo: chưa tính',
                    ),
                    if (m['reason'] != null) Text('Lý do: ${m['reason']}'),
                    if (m['status'] == 'PENDING' &&
                        ((m['team_a'] as List).contains(m['author_id'])
                                ? (m['team_b'] as List)
                                : (m['team_a'] as List))
                            .contains(room.viewerId))
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _send('match_confirm', {
                                'match_id': m['id'],
                                'expected_version': m['version'],
                              }),
                        child: const Text('Xác nhận từ đội đối thủ'),
                      ),
                    if (m['status'] == 'PENDING' &&
                        [
                          ...m['team_a'] as List,
                          ...m['team_b'] as List,
                        ].contains(room.viewerId))
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                final reason = await _reason(
                                  'Phản hồi kết quả',
                                );
                                if (reason != null) {
                                  await _send('match_dispute', {
                                    'match_id': m['id'],
                                    'expected_version': m['version'],
                                    'reason': reason,
                                  });
                                }
                              },
                        child: const Text('Không đồng ý kết quả'),
                      ),
                    if (['PENDING', 'DISPUTED'].contains(m['status'])) ...[
                      if (room.status == 'IN_PROGRESS' &&
                          m['author_id'] == room.viewerId)
                        TextButton(
                          onPressed: _busy ? null : () => _matchForm(room, m),
                          child: const Text('Tác giả sửa kết quả'),
                        ),
                      if (room.isHost || m['author_id'] == room.viewerId)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final reason = await _reason(
                                    'Hủy bản ghi trận',
                                  );
                                  if (reason != null) {
                                    await _send('match_void', {
                                      'match_id': m['id'],
                                      'expected_version': m['version'],
                                      'reason': reason,
                                    });
                                  }
                                },
                          child: const Text('Host / tác giả hủy bản ghi'),
                        ),
                    ],
                  ],
                ),
              ),
            const Text(
              'Điểm danh · host ghi nhận, người chơi có quyền phản hồi',
            ),
            const Text(
              'Host chưa được tự đánh giá điểm danh. Không trừ/cộng Trust tự động.',
            ),
            for (final player in room.members.where(
              (m) => m['status'] == 'REGISTERED' && m['is_playing'] == true,
            ))
              Builder(
                builder: (context) {
                  final record =
                      (session['attendance'] as Map)[player['id']] as Map?;
                  Future<void> mark(String action, String outcome) async {
                    final reason = await _reason(
                      action == 'attendance_dispute'
                          ? 'Phản hồi điểm danh'
                          : 'Ghi chú điểm danh',
                    );
                    if (reason != null) {
                      await _send(action, {
                        'player_id': player['id'],
                        'expected_version': record?['version'] ?? 0,
                        'outcome': outcome,
                        'reason': reason,
                      });
                    }
                  }

                  return BentoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(player['name'] as String),
                        Text(
                          record == null
                              ? 'Chưa điểm danh'
                              : '${record['outcome']} · ${record['status']} · ${record['reason']}',
                        ),
                        if (room.isHost &&
                            record == null &&
                            player['role'] != 'HOST')
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => mark('attendance_mark', 'PRESENT'),
                                child: const Text('Có mặt'),
                              ),
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => mark('attendance_mark', 'ABSENT'),
                                child: const Text('Vắng'),
                              ),
                            ],
                          ),
                        if (player['id'] == room.viewerId &&
                            !room.isHost &&
                            record?['status'] == 'RECORDED')
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => mark('attendance_dispute', ''),
                            child: const Text('Phản hồi điểm danh của tôi'),
                          ),
                        if (room.isHost && record?['status'] == 'DISPUTED')
                          Wrap(
                            children: [
                              for (final outcome in ['PRESENT', 'ABSENT'])
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () =>
                                            mark('attendance_resolve', outcome),
                                  child: Text('Chốt: $outcome'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ExpansionTile(
              title: const Text('Lịch sử thao tác mô phỏng'),
              children: [
                for (final e in (session['audit'] as List).reversed)
                  ListTile(
                    title: Text('${e['action']} · ${e['actor_id']}'),
                    subtitle: Text('${e['at']}'),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
