import 'package:supabase_flutter/supabase_flutter.dart';
import '../../feed/domain/match_draft.dart';
import '../../feed/domain/match_summary.dart';
import '../domain/court.dart';
import '../domain/create_room_draft.dart';
import '../domain/live_match_repository.dart';
import '../domain/match_room.dart';

class SupabaseMatchRepository implements LiveMatchRepository {
  SupabaseMatchRepository(this.client);
  final SupabaseClient client;
  static const roomColumns =
      'id, host_id, play_time, max_slots, current_players, status, courts(name, distance_km)';

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Vui lòng đăng nhập.');
    return id;
  }

  @override
  Future<List<MatchSummary>> feed() async {
    final rows = await client
        .from('match_results')
        .select(
          'id, court_name, team_a_names, team_b_names, score_text, winner_team, elo_change, created_at',
        )
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .map(
          (row) => MatchSummary(
            id: row['id'] as String,
            courtName: row['court_name'] as String,
            teamA: row['team_a_names'] as String,
            teamB: row['team_b_names'] as String,
            score: row['score_text'] as String,
            isWin: row['winner_team'] == 'A',
            eloChange: (row['elo_change'] as num).toInt(),
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
  }

  static MatchRoom _room(Map<String, dynamic> row) {
    final court = row['courts'] as Map<String, dynamic>?;
    return MatchRoom(
      id: row['id'] as String,
      courtName: court?['name'] as String? ?? 'Sân chưa khả dụng',
      startsAt: DateTime.parse(row['play_time'] as String).toLocal(),
      hostId: row['host_id'] as String,
      playerIds: List<String>.from(row['current_players'] as List? ?? const []),
      capacity: (row['max_slots'] as num).toInt(),
      distanceKm: (court?['distance_km'] as num?)?.toDouble(),
    );
  }

  @override
  Future<List<MatchRoom>> openRooms() async {
    final rows = await client
        .from('match_rooms')
        .select(roomColumns)
        .eq('status', 'OPEN')
        .gt('play_time', DateTime.now().toUtc().toIso8601String())
        .order('play_time', ascending: true)
        .limit(100);
    return rows
        .map(_room)
        .where((room) => room.availableSlots > 0)
        .toList(growable: false);
  }

  @override
  Future<List<Court>> courts() async {
    final rows = await client
        .from('courts')
        .select('id, name, distance_km')
        .order('name', ascending: true);
    return rows.map(Court.fromJson).toList(growable: false);
  }

  @override
  Future<void> createRoom(CreateRoomDraft draft) async {
    final userId = _userId;
    if (draft.courtId.isEmpty ||
        draft.maxSlots < 2 ||
        draft.maxSlots > 100 ||
        !draft.startsAt.isAfter(DateTime.now())) {
      throw ArgumentError('Sân, thời gian hoặc số chỗ không hợp lệ.');
    }
    await client.from('match_rooms').insert({
      'court_id': draft.courtId,
      'host_id': userId,
      'play_time': draft.startsAt.toUtc().toIso8601String(),
      'max_slots': draft.maxSlots,
      'current_players': [userId],
      'status': 'OPEN',
    });
  }

  @override
  Future<void> joinRoom(String roomId) async {
    final userId = _userId;
    // Optimistic compare-and-swap: concurrent joiners cannot overwrite one
    // another. Retry only a confirmed zero-row conflict, never a network error.
    for (var attempt = 0; attempt < 3; attempt++) {
      final row = await client
          .from('match_rooms')
          .select(roomColumns)
          .eq('id', roomId)
          .single();
      final room = _room(row);
      if (room.playerIds.contains(userId)) return;
      if (row['status'] != 'OPEN' ||
          room.availableSlots == 0 ||
          !room.startsAt.isAfter(DateTime.now())) {
        throw StateError('Kèo đã đầy hoặc đã bắt đầu.');
      }
      if (_userId != userId) {
        throw const AuthException('Phiên đăng nhập đã thay đổi.');
      }
      final players = [...room.playerIds, userId];
      var update = client
          .from('match_rooms')
          .update({
            'current_players': players,
            'status': players.length == room.capacity ? 'FULL' : 'OPEN',
          })
          .eq('id', roomId)
          .eq('status', 'OPEN')
          .eq('max_slots', room.capacity)
          .eq('play_time', row['play_time'] as String)
          .gt('play_time', DateTime.now().toUtc().toIso8601String());
      update = row['current_players'] == null
          ? update.isFilter('current_players', null)
          : update.eq('current_players', room.playerIds);
      final changed = await update.select('id');
      if (changed.isNotEmpty) return;
    }
    throw StateError(
      'Kèo vừa thay đổi hoặc bạn không có quyền tham gia. Hãy cập nhật.',
    );
  }

  @override
  Future<void> recordMatch(MatchDraft draft) async {
    final userId = _userId;
    if (draft.courtName.trim().isEmpty ||
        draft.teamA.trim().isEmpty ||
        draft.teamB.trim().isEmpty ||
        MatchDraft.validateScore(draft.score) != null) {
      throw ArgumentError('Thông tin trận đấu không hợp lệ.');
    }
    await client.rpc(
      'record_match_and_update_elo',
      params: {
        'p_user_id': userId,
        'p_court_name': draft.courtName.trim(),
        'p_team_a': draft.teamA.trim(),
        'p_team_b': draft.teamB.trim(),
        'p_score': draft.score.trim(),
        'p_is_win': draft.isWin,
      },
    );
  }
}
