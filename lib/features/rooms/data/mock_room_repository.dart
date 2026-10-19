import 'dart:convert';

import '../../feed/domain/activity.dart';

import '../../matchmaking/domain/court.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import '../domain/room_search.dart';
import 'managed_room_repository.dart';

/// Session-local sandbox. Never receives a Supabase client or writes a profile.
/// Commands validate before committing; receipts are scoped to actor + request.
class MockRoomRepository implements RoomSessionRepository, ActivityLogSource {
  MockRoomRepository({required this.userId, String displayName = 'Bạn'}) {
    people = {
      userId: displayName,
      'linh': 'Linh · giả lập',
      'minh': 'Minh · giả lập',
      'an': 'An · giả lập',
      'bao': 'Bảo · giả lập',
    };
    actorId = userId;
    reset();
  }
  final String userId;
  late final Map<String, String> people;
  @override
  late String actorId;
  @override
  int get generation => _generation;
  int _generation = 0;
  @override
  Map<String, String> get actorNames => Map.unmodifiable(people);
  final Set<String> _removedFriends = {}, _addedFriends = {}, _blocks = {};
  String _pair(String a, String b) => ([a, b]..sort()).join(':');
  @override
  bool isBlocked(String a, String b) => _blocks.contains(_pair(a, b));
  @override
  bool areFriends(String a, String b) =>
      !isBlocked(a, b) &&
      !_removedFriends.contains(_pair(a, b)) &&
      (a == b ||
          a == 'linh' ||
          b == 'linh' ||
          _addedFriends.contains(_pair(a, b)));
  void setMockFriend(String other, bool value) {
    _require(
      other != actorId && people.containsKey(other),
      'Chọn người khác để mô phỏng kết nối.',
    );
    final key = _pair(actorId, other);
    if (value) {
      _removedFriends.remove(key);
      _addedFriends.add(key);
    } else {
      _addedFriends.remove(key);
      _removedFriends.add(key);
    }
  }

  void setMockBlock(String other, bool value) {
    _require(
      other != actorId && people.containsKey(other),
      'Chọn người khác để mô phỏng chặn.',
    );
    final key = _pair(actorId, other);
    if (value) {
      _blocks.add(key);
      _removedFriends.add(key);
      _addedFriends.remove(key);
      _revokeWaiting(actorId, other, privateOnly: false);
    } else {
      _blocks.remove(key);
    }
  }

  final Map<String, int> ratings = {};
  final Map<String, Set<String>> _codeAccess = {};
  String _normalizeCode(String value) =>
      value.trim().toUpperCase().replaceFirst(RegExp(r'^#'), '');
  bool _validCode(Map<String, dynamic> room, dynamic value) =>
      value is String &&
      _normalizeCode(value).isNotEmpty &&
      room['room_code'] is String &&
      _normalizeCode(value) == _normalizeCode(room['room_code'] as String);
  void _revokeWaiting(String a, String b, {required bool privateOnly}) {
    for (final room in _rooms.values) {
      if (privateOnly && room['visibility'] != 'PRIVATE') continue;
      final host = room['host_id'];
      final affected = host == a
          ? b
          : host == b
          ? a
          : null;
      if (affected == null) continue;
      final member = _member(room, affected);
      if (member?['status'] == 'WAITLIST') {
        member!['status'] = 'CANCELLED';
        member['cancellation_kind'] = 'ACCESS_REVOKED';
        _notify(room, 'WAITLIST_ACCESS_REVOKED');
      }
    }
  }

  final Map<String, Map<String, dynamic>> _rooms = {};
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, (String, String)> _receipts = {};
  final List<Map<String, dynamic>> _notices = [];
  final List<Map<String, dynamic>> _audit = [];
  int _noticeSequence = 0;
  static const venues = [
    (
      id: 'court-a',
      name: 'Sân Đào Duy Anh (mẫu)',
      area: 'Phú Nhuận',
      address: 'Khu Đào Duy Anh, TP.HCM · địa chỉ mô phỏng',
      km: 1.8,
    ),
    (
      id: 'court-b',
      name: 'Sân Bình Thạnh (mẫu)',
      area: 'Bình Thạnh',
      address: 'Khu Bình Thạnh, TP.HCM · địa chỉ mô phỏng',
      km: 4.2,
    ),
    (
      id: 'court-c',
      name: 'Sân Thủ Đức (mẫu)',
      area: 'Thủ Đức',
      address: 'Khu Thủ Đức, TP.HCM · địa chỉ mô phỏng',
      km: 8.5,
    ),
  ];
  void selectActor(String id) {
    _require(people.containsKey(id), 'Không có người chơi giả lập này.');
    actorId = id;
  }

  void updateProfile(String name, int? elo) {
    people[userId] = name;
    if (elo != null) ratings[userId] = elo;
  }

  void reset() {
    _generation++;
    _codeAccess.clear();
    _removedFriends.clear();
    _addedFriends.clear();
    _blocks.clear();
    _rooms.clear();
    _sessions.clear();
    _receipts.clear();
    _notices.clear();
    _audit.clear();
    actorId = userId;
    ratings.addAll({
      userId: ratings[userId] ?? 750,
      'linh': 750,
      'minh': 800,
      'an': 700,
      'bao': 1000,
    });
    final start = DateTime.now().add(const Duration(days: 1));
    void seed(
      String id,
      String host,
      int court,
      List<String> members, {
      String visibility = 'PUBLIC',
      String status = 'OPEN',
      int day = 0,
    }) {
      final time = start.add(Duration(days: day));
      _rooms[id] = {
        'id': id,
        'room_code': '#XP-${1001 + _rooms.length}',
        'host_id': host,
        'court_id': venues[court].id,
        'title': 'Giao lưu ${venues[court].area}',
        'starts_at': time.toIso8601String(),
        'ends_at': time.add(const Duration(hours: 2)).toIso8601String(),
        'cancel_by': time.subtract(const Duration(hours: 1)).toIso8601String(),
        'capacity': 4,
        'min_elo': 0,
        'max_elo': 2000,
        'fee': 40000,
        'revision': 1,
        'visibility': visibility,
        'status': status,
        'host_plays': true,
        'court_label': 'Sân số 2',
        'notes': 'Cầu và nước đã gồm trong phí dự kiến.',
        'booking_status': 'UNCONFIRMED',
        'members': [
          for (final p in members)
            {
              'id': p,
              'role': p == host ? 'HOST' : 'PLAYER',
              'status': 'REGISTERED',
              'is_playing': true,
            },
        ],
      };
    }

    seed('open-demo', 'linh', 0, ['linh', 'minh']);
    seed('full-demo', 'minh', 1, ['minh', 'linh', 'an', 'bao'], day: 1);
    seed('private-demo', 'linh', 2, ['linh'], visibility: 'PRIVATE', day: 2);
    seed('host-demo', userId, 0, [userId, 'linh', 'minh', 'an'], day: 3);
    seed(
      'playing-demo',
      userId,
      1,
      [userId, 'linh', 'minh', 'an'],
      status: 'IN_PROGRESS',
      day: -1,
    );
    seed(
      'completed-demo',
      userId,
      0,
      [userId, 'linh', 'minh', 'an'],
      status: 'COMPLETED',
      day: -2,
    );
    _sessions['completed-demo'] = {
      'matches': [
        {
          'id': 'demo-confirmed',
          'author_id': userId,
          'team_a': [userId],
          'team_b': ['minh'],
          'score': '21-19',
          'winner': 'A',
          'status': 'CONFIRMED',
          'version': 2,
          'confirmed_by': ['minh'],
        },
        {
          'id': 'demo-pending',
          'author_id': userId,
          'team_a': [userId, 'linh'],
          'team_b': ['minh', 'an'],
          'score': '18-21',
          'winner': 'B',
          'status': 'PENDING',
          'version': 1,
          'confirmed_by': <String>[],
        },
      ],
      'attendance': <String, dynamic>{},
    };
  }

  @override
  List<ActivityLog> activityLogs() => [
    for (final room in _rooms.values.where((r) => r['status'] == 'COMPLETED'))
      ActivityLog(
        roomId: room['id'] as String,
        hostId: room['host_id'] as String,
        title: room['title'] as String,
        courtName: venues.firstWhere((v) => v.id == room['court_id']).name,
        isPrivate: room['visibility'] == 'PRIVATE',
        endedAt: DateTime.parse(
          (room['completed_at'] ?? room['ends_at']) as String,
        ),
        players: [
          for (final m in _members(room))
            if (m['status'] == 'REGISTERED' && m['is_playing'] == true)
              m['id'] as String,
        ],
        matches: [
          for (final m in ((_sessions[room['id']]?['matches'] as List?) ?? []))
            ActivityMatchLog(
              id: m['id'] as String,
              teamA: List<String>.from(m['team_a'] as List),
              teamB: List<String>.from(m['team_b'] as List),
              status: m['status'] as String,
              winner: m['winner'] as String,
              score: m['score'] as String,
              version: m['version'] as int,
            ),
        ],
      ),
  ];
  List<Map<String, dynamic>> _members(Map<String, dynamic> r) =>
      (r['members'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic>? _member(Map<String, dynamic> r, String id) {
    for (final m in _members(r)) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  int _reserved(Map<String, dynamic> r) => _members(r)
      .where(
        (m) =>
            m['is_playing'] == true &&
            ['REGISTERED', 'RECONFIRM'].contains(m['status']),
      )
      .length;
  bool _visible(Map<String, dynamic> r) =>
      r['host_id'] == actorId ||
      (r['status'] != 'DRAFT' &&
          (r['visibility'] == 'PUBLIC' ||
              (_codeAccess[actorId]?.contains(r['id']) == true &&
                  !isBlocked(actorId, r['host_id'] as String)) ||
              _member(r, actorId) != null));
  Map<String, dynamic> _copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  ManagedRoom _projection(Map<String, dynamic> r) {
    final v = venues.firstWhere((v) => v.id == r['court_id']);
    final n = _reserved(r);
    return ManagedRoom.fromJson({
      ..._copy(r),
      'status': r['status'] == 'OPEN' && n >= (r['capacity'] as int)
          ? 'FULL'
          : r['status'],
      'court_name': v.name,
      'court_address': '${v.address} · ${v.km} km giả lập',
      'reserved': n,
      'viewer_id': actorId,
      'is_host': r['host_id'] == actorId,
      'host_name': people[r['host_id']],
      'my_status': _member(r, actorId)?['status'],
      'members': [
        for (final m in _members(r)) {...m, 'name': people[m['id']]},
      ],
    });
  }

  @override
  Future<List<ManagedRoom>> list(
    String scope, {
    int offset = 0,
    RoomSearch? search,
  }) async {
    final rows =
        _rooms.values
            .where(
              (r) =>
                  _visible(r) &&
                  switch (scope) {
                    'discover' =>
                      r['visibility'] == 'PUBLIC' &&
                          r['status'] == 'OPEN' &&
                          DateTime.parse(r['starts_at'] as String)
                              .isAfter(DateTime.now()),
                    'connections' =>
                      r['visibility'] == 'PRIVATE' &&
                          r['status'] == 'OPEN' &&
                          (r['host_id'] == actorId ||
                              [
                                'REGISTERED',
                                'RECONFIRM',
                                'WAITLIST',
                              ].contains(_member(r, actorId)?['status'])),
                    'mine' =>
                      (r['host_id'] == actorId ||
                              [
                                'REGISTERED',
                                'RECONFIRM',
                                'WAITLIST',
                              ].contains(_member(r, actorId)?['status'])) &&
                          !['COMPLETED', 'CANCELLED'].contains(r['status']),
                    'history' =>
                      (r['host_id'] == actorId ||
                              _member(r, actorId) != null) &&
                          ['COMPLETED', 'CANCELLED'].contains(r['status']),
                    _ => false,
                  },
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['starts_at'] as String).compareTo(b['starts_at'] as String),
          );
    final filtered = rows.where((r) {
      if (search == null || scope != 'discover') return true;
      final v = venues.firstWhere((v) => v.id == r['court_id']);
      final time = DateTime.parse(r['starts_at'] as String).toLocal();
      return (search.area == null || v.area == search.area) &&
          (search.maxDistanceKm == null || v.km <= search.maxDistanceKm!) &&
          (!search.availableOnly || _reserved(r) < (r['capacity'] as int)) &&
          (search.skill == null ||
              (search.skill! >= (r['min_elo'] as int) &&
                  search.skill! <= (r['max_elo'] as int))) &&
          (search.maxFee == null || (r['fee'] as int) <= search.maxFee!) &&
          (search.date == null ||
              (time.year == search.date!.year &&
                  time.month == search.date!.month &&
                  time.day == search.date!.day));
    });
    return filtered.skip(offset).take(50).map(_projection).toList();
  }

  @override
  Future<ManagedRoom?> get(String id) async {
    final r = _rooms[id];
    if (r != null && _visible(r)) return _projection(r);
    for (final room in _rooms.values) {
      if (room['status'] != 'DRAFT' &&
          !isBlocked(actorId, room['host_id'] as String) &&
          _validCode(room, id)) {
        _codeAccess.putIfAbsent(actorId, () => {}).add(room['id'] as String);
        return _projection(room);
      }
    }
    return null;
  }

  @override
  Future<List<Court>> courts() async => [
    for (final v in venues)
      Court(id: v.id, name: '${v.name} · ${v.area}', distanceKm: v.km),
  ];
  @override
  Future<List<Map<String, dynamic>>> notices() async => [
    for (final n in _notices.reversed)
      if (n['recipient'] == actorId) _copy(n),
  ];
  @override
  Future<void> readNotices(int through) async {
    for (final n in _notices) {
      if (n['recipient'] == actorId && (n['id'] as int) <= through) {
        n['read'] = true;
      }
    }
  }

  void _require(bool condition, String message) {
    if (!condition) throw RoomRuleException(message);
  }

  void _notify(Map<String, dynamic> r, String kind) {
    for (final m in _members(r)) {
      _notices.add({
        'id': ++_noticeSequence,
        'recipient': m['id'],
        'room_id': r['id'],
        'kind': kind,
        'revision': r['revision'],
        'created_at': DateTime.now().toIso8601String(),
        'read': false,
      });
    }
  }

  bool _conflicts(String person, Map<String, dynamic> candidate) {
    final start = DateTime.parse(candidate['starts_at'] as String),
        end = DateTime.parse(candidate['ends_at'] as String);
    return _rooms.values.any(
      (r) =>
          r['id'] != candidate['id'] &&
          ['OPEN', 'IN_PROGRESS'].contains(r['status']) &&
          (r['host_id'] == person ||
              _member(r, person)?['status'] == 'REGISTERED') &&
          DateTime.parse(r['starts_at'] as String).isBefore(end) &&
          DateTime.parse(r['ends_at'] as String).isAfter(start),
    );
  }

  void _promote(Map<String, dynamic> r) {
    if (r['status'] != 'OPEN' ||
        !DateTime.parse(r['starts_at'] as String).isAfter(DateTime.now())) {
      return;
    }
    for (final m in _members(r)) {
      if (_reserved(r) >= (r['capacity'] as int)) break;
      if (m['status'] == 'WAITLIST' &&
          _eligible(m['id'] as String, r) &&
          !_conflicts(m['id'] as String, r) &&
          (r['visibility'] == 'PUBLIC' || m['admission'] == 'ROOM_CODE')) {
        m['status'] = 'REGISTERED';
        _notify(r, 'PROMOTED');
      }
    }
  }

  bool _eligible(String id, Map<String, dynamic> r) =>
      !isBlocked(id, r['host_id'] as String) &&
      (ratings[id] ?? 750) >= (r['min_elo'] as int) &&
      (ratings[id] ?? 750) <= (r['max_elo'] as int);

  @override
  Future<String> execute(RoomCommand c) async {
    final key = '$actorId:${c.requestId}',
        fingerprint = jsonEncode([c.action, c.roomId, c.payload]);
    final receipt = _receipts[key];
    if (receipt != null) {
      _require(
        receipt.$1 == fingerprint,
        'Yêu cầu đã được dùng với dữ liệu khác.',
      );
      return receipt.$2;
    }
    // Work on copies; a rejected command never partially changes the store.
    final id = c.action == 'create' ? newRoomRequestId() : c.roomId!;
    final existing = _rooms[id];
    _require(
      c.action == 'create' ||
          (existing != null &&
              (_visible(existing) ||
                  (['join', 'waitlist'].contains(c.action) &&
                      existing['status'] != 'DRAFT' &&
                      _validCode(existing, c.payload['room_code'])))),
      'Buổi chơi không khả dụng.',
    );
    final r = existing == null
        ? <String, dynamic>{
            'id': id,
            'host_id': actorId,
            'revision': 1,
            'members': <Map<String, dynamic>>[],
          }
        : _copy(existing);
    final p = c.payload, host = r['host_id'] == actorId;
    final m = _member(r, actorId);
    void hostOnly() => _require(host, 'Chỉ host được thực hiện thao tác này.');
    void openOnly() => _require(r['status'] == 'OPEN', 'Buổi đã đóng đăng ký.');
    void revision() => _require(
      p['expected_revision'] == r['revision'],
      'Điều kiện đã đổi. Tải lại và xác nhận lại.',
    );
    if (['create', 'edit'].contains(c.action)) {
      hostOnly();
      if (c.action == 'edit') {
        revision();
        _require(
          ['DRAFT', 'OPEN'].contains(r['status']),
          'Không thể sửa buổi đã bắt đầu.',
        );
      }
      final next = {...r, ...p};
      final code = c.action == 'create'
          ? (p['room_code'] as String? ??
                '#XP-${newRoomRequestId().replaceAll('-', '').substring(0, 6).toUpperCase()}')
          : r['room_code'] as String;
      _require(
        RegExp(r'^XP-[A-Z0-9]{4,8}$').hasMatch(_normalizeCode(code)) &&
            !_rooms.values.any(
              (other) => other['id'] != id && _validCode(other, code),
            ),
        'Mã phòng không hợp lệ hoặc bị trùng.',
      );
      _require(
        c.action != 'edit' ||
            p['room_code'] == null ||
            _validCode(r, p['room_code']),
        'Không đổi mã phòng khi sửa điều kiện.',
      );
      _require(
        p['host_plays'] != true || _eligible(actorId, next),
        'Trình của host ngoài khoảng đã chọn.',
      );
      final start = DateTime.tryParse('${p['starts_at']}'),
          end = DateTime.tryParse('${p['ends_at']}'),
          cancel = DateTime.tryParse('${p['cancel_by']}');
      _require(
        venues.any((v) => v.id == p['court_id']) &&
            start != null &&
            end != null &&
            cancel != null &&
            start.isAfter(DateTime.now()) &&
            end.isAfter(start) &&
            !cancel.isAfter(start),
        'Kiểm tra sân và thời gian.',
      );
      _require(
        (p['title'] as String? ?? '').trim().isNotEmpty &&
            (p['capacity'] as int) >= 2 &&
            (p['capacity'] as int) <= 100 &&
            (p['fee'] as int) >= 0 &&
            (p['min_elo'] as int) <= (p['max_elo'] as int) &&
            ['PUBLIC', 'PRIVATE'].contains(p['visibility']),
        'Điều kiện phòng không hợp lệ.',
      );
      _require(
        p['draft'] == true || !_conflicts(actorId, next),
        'Host đã có lịch trùng.',
      );
      final roster = _members(r);
      if (m == null) {
        roster.add({
          'id': actorId,
          'role': 'HOST',
          'status': 'REGISTERED',
          'is_playing': p['host_plays'],
        });
      } else {
        m['is_playing'] = p['host_plays'];
      }
      _require(
        _reserved(r) <= (p['capacity'] as int),
        'Số chỗ nhỏ hơn số người đã đăng ký.',
      );
      if (c.action == 'edit' &&
          ['court_id', 'starts_at', 'ends_at'].any((key) => r[key] != p[key])) {
        r['booking_status'] = 'UNCONFIRMED';
      }
      r.addAll(p);
      r['room_code'] = '#${_normalizeCode(code)}';
      r['members'] = roster;
      r['status'] = p['draft'] == true ? 'DRAFT' : 'OPEN';
      if (c.action == 'edit') {
        r['revision'] = (r['revision'] as int) + 1;
        for (final player in roster) {
          if (player['id'] != actorId && player['status'] == 'REGISTERED') {
            player['status'] = 'RECONFIRM';
          }
          if (player['status'] == 'WAITLIST') player['status'] = 'CANCELLED';
        }
      }
    } else if (['join', 'waitlist', 'reconfirm'].contains(c.action)) {
      openOnly();
      revision();
      _require(
        _eligible(actorId, r),
        'Trình giả lập của bạn ngoài khoảng phòng.',
      );
      _require(
        DateTime.parse(r['starts_at'] as String).isAfter(DateTime.now()),
        'Đã qua giờ đăng ký.',
      );
      _require(
        !host &&
            (r['visibility'] == 'PUBLIC' ||
                (c.action == 'reconfirm' && m?['status'] == 'RECONFIRM') ||
                _validCode(r, p['room_code'])),
        'Phòng riêng cần mã phòng hợp lệ; không yêu cầu kết bạn với host.',
      );
      if (c.action == 'reconfirm') {
        _require(m?['status'] == 'RECONFIRM', 'Không có yêu cầu xác nhận lại.');
        _require(!_conflicts(actorId, r), 'Bạn có lịch trùng.');
        m!['status'] = 'REGISTERED';
      } else {
        _require(
          m == null || m['status'] == 'CANCELLED',
          'Bạn đã có đăng ký trong phòng.',
        );
        final waiting = c.action == 'waitlist';
        _require(
          waiting
              ? _reserved(r) >= (r['capacity'] as int)
              : _reserved(r) < (r['capacity'] as int),
          waiting
              ? 'Phòng còn chỗ, hãy đăng ký trực tiếp.'
              : 'Phòng đã đủ người.',
        );
        _require(waiting || !_conflicts(actorId, r), 'Bạn có lịch trùng.');
        final entry = {
          'id': actorId,
          'role': 'PLAYER',
          'status': waiting ? 'WAITLIST' : 'REGISTERED',
          'is_playing': true,
          'admission': r['visibility'] == 'PRIVATE' ? 'ROOM_CODE' : 'PUBLIC',
        };
        if (m != null) _members(r).remove(m);
        _members(r).add(entry);
      }
    } else if (c.action == 'leave') {
      openOnly();
      _require(
        !host &&
            m != null &&
            ['REGISTERED', 'WAITLIST', 'RECONFIRM'].contains(m['status']),
        'Không có đăng ký để hủy.',
      );
      m!['cancellation_kind'] = m['status'] == 'WAITLIST'
          ? 'WAITLIST_LEFT'
          : m['status'] == 'RECONFIRM'
          ? 'TERMS_DECLINED'
          : DateTime.now().isAfter(DateTime.parse(r['cancel_by'] as String))
          ? 'LATE'
          : 'ON_TIME';
      m['status'] = 'CANCELLED';
      _promote(r);
    } else if (c.action == 'publish') {
      hostOnly();
      _require(r['status'] == 'DRAFT', 'Chỉ mở đăng ký từ bản nháp.');
      _require(
        DateTime.parse(r['starts_at'] as String).isAfter(DateTime.now()) &&
            !_conflicts(actorId, r),
        'Lịch đã qua hoặc trùng buổi khác.',
      );
      r['status'] = 'OPEN';
    } else if (c.action == 'cancel') {
      hostOnly();
      _require(
        ['DRAFT', 'OPEN'].contains(r['status']),
        'Không thể hủy buổi đã bắt đầu.',
      );
      _require('${p['reason'] ?? ''}'.trim().isNotEmpty, 'Cần lý do hủy.');
      r['status'] = 'CANCELLED';
      r['cancellation_reason'] = p['reason'];
    } else if (c.action == 'release_unconfirmed') {
      hostOnly();
      openOnly();
      _require(
        !DateTime.parse(r['starts_at'] as String).isAfter(DateTime.now()),
        'Chưa đến giờ giải phóng chỗ.',
      );
      for (final player in _members(r)) {
        if (player['status'] == 'RECONFIRM') player['status'] = 'CANCELLED';
      }
    } else if (c.action == 'start') {
      hostOnly();
      openOnly();
      _require(
        !_members(r).any((m) => m['status'] == 'RECONFIRM'),
        'Còn người chưa xác nhận lại.',
      );
      _require(_reserved(r) >= 2, 'Cần ít nhất hai người chơi.');
      _require(
        !_rooms.values.any(
          (other) =>
              other['id'] != id &&
              other['status'] == 'IN_PROGRESS' &&
              _members(r).any(
                (m) =>
                    (m['status'] == 'REGISTERED' || m['id'] == r['host_id']) &&
                    (other['host_id'] == m['id'] ||
                        _member(other, m['id'] as String)?['status'] ==
                            'REGISTERED'),
              ),
        ),
        'Có người vẫn ở buổi khác đang diễn ra.',
      );
      // Sandbox explicitly allows early start; no clock/GPS simulation required.
      r['status'] = 'IN_PROGRESS';
      for (final player in _members(r)) {
        if (player['status'] == 'WAITLIST') player['status'] = 'CANCELLED';
      }
    } else if (c.action == 'finish') {
      hostOnly();
      _require(r['status'] == 'IN_PROGRESS', 'Buổi chưa bắt đầu.');
      r['status'] = 'COMPLETED';
      r['completed_at'] = DateTime.now().toIso8601String();
    } else if (c.action == 'booking') {
      hostOnly();
      _require(['DRAFT', 'OPEN'].contains(r['status']), 'Buổi đã bắt đầu.');
      r['booking_status'] = p['confirmed'] == true
          ? 'HOST_CONFIRMED'
          : 'UNCONFIRMED';
    } else {
      _sessionCommand(c, r);
    }
    _rooms[id] = r;
    _receipts[key] = (fingerprint, id);
    _audit.add({
      'actor_id': actorId,
      'request_id': c.requestId,
      'action': c.action,
      'room_id': id,
      'at': DateTime.now().toIso8601String(),
      'payload': _copy(Map<String, dynamic>.from(c.payload)),
    });
    _notify(
      r,
      c.action == 'edit'
          ? 'TERMS_CHANGED'
          : c.action == 'finish'
          ? 'COMPLETED'
          : c.action == 'cancel'
          ? 'HOST_CANCELLED'
          : c.action.toUpperCase(),
    );
    return id;
  }

  Map<String, dynamic> _emptySession() => {
    'matches': <Map<String, dynamic>>[],
    'attendance': <String, dynamic>{},
  };
  @override
  Future<Map<String, dynamic>> session(String roomId) async {
    final r = _rooms[roomId];
    _require(
      r != null &&
          (r['host_id'] == actorId ||
              _member(r, actorId)?['status'] == 'REGISTERED'),
      'Chỉ thành viên được xem buổi.',
    );
    return {
      ..._copy(_sessions[roomId] ?? _emptySession()),
      'booking_status': r!['booking_status'],
      'audit': [
        for (final e in _audit.where((e) => e['room_id'] == roomId)) _copy(e),
      ],
    };
  }

  void _sessionCommand(RoomCommand c, Map<String, dynamic> r) {
    _require(
      ['IN_PROGRESS', 'COMPLETED'].contains(r['status']),
      'Buổi chưa bắt đầu.',
    );
    final member = _member(r, actorId), host = r['host_id'] == actorId;
    _require(
      host || member?['status'] == 'REGISTERED',
      'Bạn không thuộc buổi chơi.',
    );
    final s = _copy(_sessions[r['id']] ?? _emptySession()), p = c.payload;
    final matches = (s['matches'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic>? match;
    for (final item in matches) {
      if (item['id'] == p['match_id']) match = item;
    }
    if (['match_create', 'match_edit'].contains(c.action)) {
      _require(
        r['status'] == 'IN_PROGRESS',
        'Chỉ ghi/sửa trận khi buổi đang chơi.',
      );
      final a = List<String>.from(p['team_a'] as List),
          b = List<String>.from(p['team_b'] as List);
      final ids = [...a, ...b];
      _require(
        a.length == b.length &&
            [1, 2].contains(a.length) &&
            ids.toSet().length == ids.length &&
            ids.every(
              (id) =>
                  _member(r, id)?['status'] == 'REGISTERED' &&
                  _member(r, id)?['is_playing'] == true,
            ),
        'Chọn 2 hoặc 4 người chơi khác nhau thuộc buổi.',
      );
      _require(
        ids.contains(actorId),
        'Người ghi kết quả phải trực tiếp chơi trận đó.',
      );
      _require(['A', 'B'].contains(p['winner']), 'Chọn đội thắng.');
      final score = '${p['score'] ?? ''}'.trim();
      _require(
        RegExp(r'^\d{1,2}-\d{1,2}( \d{1,2}-\d{1,2}){0,2}$').hasMatch(score) &&
            score.split(' ').every((set) {
              final n = set.split('-').map(int.parse).toList();
              return n[0] != n[1] && n.every((v) => v <= 30);
            }),
        'Nhập 1–3 set, ví dụ 21-19 21-16; không hòa set.',
      );
      final sets = score
          .split(' ')
          .map((set) => set.split('-').map(int.parse).toList())
          .toList();
      final aw = sets.where((n) => n[0] > n[1]).length, bw = sets.length - aw;
      _require(
        aw != bw && (p['winner'] == 'A' ? aw > bw : bw > aw),
        'Đội thắng phải khớp tỉ số set.',
      );
      if (c.action == 'match_edit') {
        _require(
          match != null &&
              match['author_id'] == actorId &&
              ['PENDING', 'DISPUTED'].contains(match['status']),
          'Chỉ tác giả được sửa trận chưa chốt.',
        );
        _require(
          p['expected_version'] == match!['version'],
          'Kết quả đã thay đổi. Tải lại.',
        );
      }
      final value = {
        'id': match?['id'] ?? newRoomRequestId(),
        'author_id': actorId,
        'team_a': a,
        'team_b': b,
        'score': score,
        'winner': p['winner'],
        'status': 'PENDING',
        'version': (match?['version'] as int? ?? 0) + 1,
        'confirmed_by': <String>[],
        'reason': null,
      };
      if (match == null) {
        matches.add(value);
      } else {
        matches[matches.indexOf(match)] = value;
      }
    } else if ([
      'match_confirm',
      'match_dispute',
      'match_void',
    ].contains(c.action)) {
      _require(match != null, 'Không tìm thấy trận.');
      _require(
        p['expected_version'] == match!['version'],
        'Kết quả đã thay đổi. Tải lại.',
      );
      _require(
        match['status'] == 'PENDING' ||
            (c.action == 'match_void' && match['status'] == 'DISPUTED'),
        'Trận đã được xử lý.',
      );
      final a = List<String>.from(match['team_a'] as List),
          b = List<String>.from(match['team_b'] as List);
      if (c.action == 'match_confirm') {
        final opposite = a.contains(match['author_id']) ? b : a;
        _require(
          opposite.contains(actorId),
          'Cần một người bên đối thủ xác nhận.',
        );
        match['status'] = 'CONFIRMED';
        match['confirmed_by'] = [actorId];
      } else {
        _require(
          c.action == 'match_void'
              ? (host || match['author_id'] == actorId)
              : [...a, ...b].contains(actorId),
          'Không có quyền xử lý trận.',
        );
        _require('${p['reason'] ?? ''}'.trim().isNotEmpty, 'Cần nhập lý do.');
        match['status'] = c.action == 'match_void' ? 'VOID' : 'DISPUTED';
        match['reason'] = p['reason'];
      }
      match['version'] = (match['version'] as int) + 1;
    } else if ([
      'attendance_mark',
      'attendance_dispute',
      'attendance_resolve',
    ].contains(c.action)) {
      final id = p['player_id'] as String;
      _require(
        _member(r, id)?['status'] == 'REGISTERED' &&
            _member(r, id)?['is_playing'] == true,
        'Chỉ điểm danh người đăng ký chơi.',
      );
      final records = s['attendance'] as Map<String, dynamic>;
      final old = records[id] as Map<String, dynamic>?;
      _require(
        p['expected_version'] == (old?['version'] ?? 0),
        'Điểm danh đã đổi. Tải lại.',
      );
      if (c.action == 'attendance_dispute') {
        _require(
          id == actorId && old != null && old['status'] == 'RECORDED',
          'Chỉ phản hồi điểm danh của bản thân.',
        );
        _require(
          '${p['reason'] ?? ''}'.trim().isNotEmpty,
          'Cần lý do phản hồi.',
        );
        records[id] = {
          ...old!,
          'status': 'DISPUTED',
          'reason': p['reason'],
          'version': (old['version'] as int) + 1,
        };
      } else {
        _require(host, 'Chỉ host được điểm danh.');
        _require(
          id != actorId,
          'Host không tự đánh giá điểm danh của mình trong mock này.',
        );
        _require(
          ['PRESENT', 'ABSENT'].contains(p['outcome']),
          'Chọn có mặt hoặc vắng.',
        );
        _require(
          c.action == 'attendance_resolve'
              ? (old?['status'] == 'DISPUTED')
              : old == null,
          'Điểm danh đã có; dùng luồng phản hồi.',
        );
        _require(
          '${p['reason'] ?? ''}'.trim().isNotEmpty,
          'Cần ghi chú điểm danh/xử lý.',
        );
        records[id] = {
          'outcome': p['outcome'],
          'status': c.action == 'attendance_resolve' ? 'RESOLVED' : 'RECORDED',
          'reason': p['reason'],
          'version': (old?['version'] as int? ?? 0) + 1,
          'actor_id': actorId,
        };
      }
    } else {
      throw const RoomRuleException('Thao tác chưa được hỗ trợ trong mock.');
    }
    _sessions[r['id'] as String] = s;
  }
}
