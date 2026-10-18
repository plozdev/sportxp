import 'package:supabase_flutter/supabase_flutter.dart';

import '../../feed/domain/match_summary.dart';
import '../../matchmaking/domain/court.dart';
import '../domain/player_profile.dart';

class ProfileRepository {
  ProfileRepository(this.client);
  final SupabaseClient client;

  static const columnsWithCourt =
      'id, display_name, avatar_url, elo_rating, tier_name, trust_score, win_streak, home_court_id, created_at, onboarding_step, courts(id, name, distance_km)';
  static const basicColumns =
      'id, display_name, avatar_url, elo_rating, tier_name, trust_score, win_streak, home_court_id, created_at, onboarding_step';
  static const leaderboardColumns =
      'id, display_name, avatar_url, elo_rating, tier_name, trust_score, win_streak';

  Future<PlayerProfile?> currentProfile() async {
    final id = client.auth.currentUser?.id;
    if (id == null) return null;
    try {
      final row = await client
          .from('profiles')
          .select(columnsWithCourt)
          .eq('id', id)
          .maybeSingle();
      if (row != null) return PlayerProfile.fromJson(row);
    } catch (_) {
      // Fallback nếu relation courts chưa grant SELECT hoặc tên alias khác
      final fallbackRow = await client
          .from('profiles')
          .select(basicColumns)
          .eq('id', id)
          .maybeSingle();
      if (fallbackRow != null) return PlayerProfile.fromJson(fallbackRow);
    }
    return null;
  }

  Future<List<PlayerProfile>> leaderboard() async {
    final rows = await client
        .from('profiles')
        .select(leaderboardColumns)
        .not('elo_rating', 'is', null)
        .eq('onboarding_step', 5)
        .order('elo_rating', ascending: false)
        .order('id', ascending: true)
        .limit(100);
    return rows.map(PlayerProfile.fromJson).toList(growable: false);
  }

  Future<void> updateProfile({
    String? displayName,
    String? homeCourtId,
  }) async {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Vui lòng đăng nhập.');
    final updates = <String, dynamic>{};
    if (displayName != null && displayName.trim().isNotEmpty) {
      updates['display_name'] = displayName.trim();
    }
    if (homeCourtId != null) {
      updates['home_court_id'] = homeCourtId.isEmpty ? null : homeCourtId;
    }
    if (updates.isEmpty) return;
    await client.from('profiles').update(updates).eq('id', id);
  }

  Future<List<Court>> loadCourts() async {
    try {
      final rows = await client
          .from('courts')
          .select('id, name, distance_km')
          .order('name', ascending: true);
      return rows.map(Court.fromJson).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<MatchSummary>> playerRecentMatches(String playerName) async {
    try {
      final rows = await client
          .from('match_results')
          .select(
            'id, court_name, team_a_names, team_b_names, score_text, winner_team, elo_change, created_at',
          )
          .order('created_at', ascending: false)
          .limit(20);
      final list = rows
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
          .where((m) =>
              m.teamA.toLowerCase().contains(playerName.toLowerCase()) ||
              m.teamB.toLowerCase().contains(playerName.toLowerCase()))
          .take(5)
          .toList(growable: false);
      return list;
    } catch (_) {
      return const [];
    }
  }
}
