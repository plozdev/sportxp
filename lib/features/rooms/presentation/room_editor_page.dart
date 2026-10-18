import 'dart:convert';

import 'package:flutter/material.dart';

import '../../matchmaking/domain/court.dart';
import '../data/managed_room_repository.dart';
import '../domain/managed_room.dart';

class RoomEditorPage extends StatefulWidget {
  const RoomEditorPage({super.key, required this.repository, this.room});
  final ManagedRoomRepository repository;
  final ManagedRoom? room;
  @override
  State<RoomEditorPage> createState() => _RoomEditorPageState();
}

class _RoomEditorPageState extends State<RoomEditorPage> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late Future<List<Court>> _courts;
  late DateTime _start;
  String? _courtId, _error;
  bool _private = false, _plays = true, _draft = false, _busy = false;
  RoomCommand? _pending;
  TextEditingController field(String name) => _fields[name]!;
  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _start = room?.startsAt ?? DateTime.now().add(const Duration(hours: 2));
    _courtId = room?.courtId;
    _private = room?.visibility == 'PRIVATE';
    _plays = room?.hostPlays ?? true;
    _draft = room?.status == 'DRAFT';
    final defaults = {
      'Tên buổi chơi': room?.title ?? 'Kèo giao lưu',
      'Thời lượng (phút)':
          '${room?.endsAt.difference(room.startsAt).inMinutes ?? 120}',
      'Số chỗ chơi': '${room?.capacity ?? 4}',
      'Elo tối thiểu': '${room?.minElo ?? 0}',
      'Elo tối đa': '${room?.maxElo ?? 2000}',
      'Phí dự kiến/người (VND)': '${room?.fee ?? 40000}',
      'Hủy miễn ảnh hưởng trước giờ chơi (phút)':
          '${room?.startsAt.difference(room.cancelBy).inMinutes ?? 60}',
      'Sân con / số sân': room?.courtLabel ?? '',
      'Ghi chú / phí đã gồm': room?.notes ?? '',
    };
    for (final e in defaults.entries) {
      _fields[e.key] = TextEditingController(text: e.value);
    }
    _courts = widget.repository.courts();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start.isAfter(now) ? _start : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time != null && mounted) {
      setState(
        () => _start = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_courtId == null || !_start.isAfter(DateTime.now())) {
      setState(() => _error = 'Chọn sân và giờ bắt đầu trong tương lai.');
      return;
    }
    final min = int.parse(field('Elo tối thiểu').text),
        max = int.parse(field('Elo tối đa').text);
    if (max < min) {
      setState(
        () => _error = 'Elo tối đa phải lớn hơn hoặc bằng Elo tối thiểu.',
      );
      return;
    }
    final payload = <String, dynamic>{
      'court_id': _courtId,
      'title': field('Tên buổi chơi').text.trim(),
      'starts_at': _start.toUtc().toIso8601String(),
      'ends_at': _start
          .add(Duration(minutes: int.parse(field('Thời lượng (phút)').text)))
          .toUtc()
          .toIso8601String(),
      'cancel_by': _start
          .subtract(
            Duration(
              minutes: int.parse(
                field('Hủy miễn ảnh hưởng trước giờ chơi (phút)').text,
              ),
            ),
          )
          .toUtc()
          .toIso8601String(),
      'capacity': int.parse(field('Số chỗ chơi').text),
      'min_elo': min,
      'max_elo': max,
      'fee': int.parse(field('Phí dự kiến/người (VND)').text),
      'visibility': _private ? 'PRIVATE' : 'PUBLIC',
      'host_plays': _plays,
      'notes': field('Ghi chú / phí đã gồm').text,
      'court_label': field('Sân con / số sân').text,
      'draft': _draft,
      if (widget.room != null) 'expected_revision': widget.room!.revision,
    };
    if (_pending == null ||
        jsonEncode(_pending!.payload) != jsonEncode(payload)) {
      _pending = RoomCommand(
        widget.room == null ? 'create' : 'edit',
        roomId: widget.room?.id,
        payload: payload,
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.execute(_pending!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = roomFailure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room == null ? 'Tạo buổi chơi' : 'Sửa điều kiện buổi chơi',
        ),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.room != null)
                const Text(
                  'Lưu thay đổi sẽ yêu cầu người đã đăng ký xác nhận lại; danh sách chờ được hủy để đăng ký theo điều kiện mới.',
                ),
              const SizedBox(height: 12),
              FutureBuilder<List<Court>>(
                future: _courts,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('Chưa tải được sân.'),
                        TextButton(
                          onPressed: () => setState(
                            () => _courts = widget.repository.courts(),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty) {
                    return const Text('Chưa có sân để tạo phòng.');
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _courtId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sân cầu'),
                    items: snapshot.data!
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (id) => setState(() => _courtId = id),
                    validator: (id) => id == null ? 'Chọn sân.' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _pick,
                child: Text(
                  'Bắt đầu: ${_start.day}/${_start.month}/${_start.year} ${TimeOfDay.fromDateTime(_start).format(context)}',
                ),
              ),
              for (final name in _fields.keys)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextFormField(
                    controller: field(name),
                    enabled: !_busy,
                    keyboardType:
                        [
                          'Tên buổi chơi',
                          'Sân con / số sân',
                          'Ghi chú / phí đã gồm',
                        ].contains(name)
                        ? TextInputType.text
                        : TextInputType.number,
                    decoration: InputDecoration(labelText: name),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (name == 'Tên buổi chơi') {
                        return text.isEmpty || text.length > 100
                            ? 'Nhập từ 1 đến 100 ký tự.'
                            : null;
                      }
                      if (name == 'Sân con / số sân') {
                        return text.length > 100 ? 'Tối đa 100 ký tự.' : null;
                      }
                      if (name == 'Ghi chú / phí đã gồm') {
                        return text.length > 2000 ? 'Tối đa 2000 ký tự.' : null;
                      }
                      final n = int.tryParse(text);
                      if (n == null || n < 0 || n > 2147483647) {
                        return 'Nhập số nguyên từ 0 đến 2147483647.';
                      }
                      if (name == 'Số chỗ chơi' && (n < 2 || n > 100)) {
                        return 'Từ 2 đến 100 chỗ.';
                      }
                      if (name == 'Thời lượng (phút)' && n < 1) {
                        return 'Thời lượng phải lớn hơn 0.';
                      }
                      return null;
                    },
                  ),
                ),
              SwitchListTile(
                title: const Text('Phòng Private'),
                subtitle: const Text(
                  'Chỉ host và bạn bè hai chiều có thể đăng ký mới.',
                ),
                value: _private,
                onChanged: _busy ? null : (v) => setState(() => _private = v),
              ),
              SwitchListTile(
                title: const Text('Host cũng chơi'),
                subtitle: const Text(
                  'Tắt nếu chỉ tổ chức; không chiếm chỗ chơi.',
                ),
                value: _plays,
                onChanged: _busy ? null : (v) => setState(() => _plays = v),
              ),
              if (widget.room == null || widget.room!.status == 'DRAFT')
                SwitchListTile(
                  title: const Text('Lưu nháp, chưa mở đăng ký'),
                  value: _draft,
                  onChanged: _busy ? null : (v) => setState(() => _draft = v),
                ),
              const Text(
                'Phí chỉ là dự kiến, chưa phải thanh toán hay xác nhận đặt sân. Danh sách chờ có thể tự lên chỗ khi còn đủ điều kiện.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'ĐANG LƯU…' : 'LƯU BUỔI CHƠI'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}
