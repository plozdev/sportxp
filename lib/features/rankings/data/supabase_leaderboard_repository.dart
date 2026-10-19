import 'package:supabase_flutter/supabase_flutter.dart';

import '../../matchmaking/domain/court.dart';
import '../../profile/domain/player_profile.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/rank_tier.dart';

/// Triển khai thực tế với Supabase khi ứng dụng kết nối Backend.
class SupabaseLeaderboardRepository implements LeaderboardRepository {
  const SupabaseLeaderboardRepository(this.client);
  final SupabaseClient client;

  static const _columns =
      'id, display_name, avatar_url, elo_rating, tier_name, trust_score, win_streak, home_court_id, courts(id, name, distance_km)';

  @override
  Future<List<Court>> getCourts() async {
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

  @override
  Future<List<PlayerProfile>> getCourtLeaderboard({
    required String courtId,
    int? limit,
  }) async {
    try {
      var query = client
          .from('profiles')
          .select(_columns)
          .not('elo_rating', 'is', null)
          .eq('onboarding_step', 5)
          .eq('home_court_id', courtId)
          .order('elo_rating', ascending: false)
          .order('id', ascending: true);

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      final rows = await query;
      return rows.map(PlayerProfile.fromJson).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<PlayerProfile>> getNearbyPlayers({
    required String courtId,
    required String playerId,
    int radius = 5,
  }) async {
    final all = await getCourtLeaderboard(courtId: courtId);
    final index = all.indexWhere((p) => p.id == playerId);
    if (index == -1) {
      return all.take(radius * 2 + 1).toList();
    }
    final start = (index - radius).clamp(0, all.length);
    final end = (index + radius + 1).clamp(0, all.length);
    return all.sublist(start, end);
  }

  @override
  Future<PlayerCourtRank?> getPlayerCourtRank({
    required String playerId,
    required String courtId,
  }) async {
    try {
      final list = await getCourtLeaderboard(courtId: courtId);
      final index = list.indexWhere((p) => p.id == playerId);
      if (index == -1) return null;

      final player = list[index];
      final rank = index + 1;
      final total = list.length;

      int? pointsToNext;
      String? nextPlayerName;
      if (index > 0) {
        final above = list[index - 1];
        pointsToNext =
            ((above.eloRating ?? 0) - (player.eloRating ?? 0)).abs() + 1;
        nextPlayerName = above.displayName;
      }

      final courts = await getCourts();
      final courtName = courts.where((c) => c.id == courtId).firstOrNull?.name ?? 'Sân thi đấu';

      return PlayerCourtRank(
        rank: rank,
        totalPlayers: total,
        courtName: courtName,
        courtId: courtId,
        pointsToNextRank: pointsToNext,
        nextPlayerName: nextPlayerName,
        isPodium: rank <= 3,
        tier: player.eloRating != null ? RankTier.fromElo(player.eloRating!) : null,
        elo: player.eloRating,
        rankDelta: player.rankDelta,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PlayerProfile>> getLeaderboard({String? courtId}) async {
    if (courtId != null) {
      return getCourtLeaderboard(courtId: courtId);
    }
    final courts = await getCourts();
    final firstId = courts.firstOrNull?.id ?? 'court-a';
    return getCourtLeaderboard(courtId: firstId);
  }
}
