import '../../matchmaking/domain/court.dart';
import '../../profile/domain/player_profile.dart';
import 'rank_tier.dart';

/// Thông tin vị trí xếp hạng của người chơi trong 1 sân
class PlayerCourtRank {
  const PlayerCourtRank({
    required this.rank,
    required this.totalPlayers,
    required this.courtName,
    required this.courtId,
    this.pointsToNextRank,
    this.nextPlayerName,
    this.isPodium = false,
    this.tier,
    this.elo,
  });

  final int rank;
  final int totalPlayers;
  final String courtName;
  final String courtId;
  final int? pointsToNextRank;
  final String? nextPlayerName;
  final bool isPodium;
  final RankTier? tier;
  final int? elo;

  bool get isTopOne => rank == 1;
}

/// Interface trừu tượng hóa cho Bảng Xếp Hạng theo từng SÂN (Clean Architecture)
/// Cho phép hoán đổi 100% giữa Mock Repository trong MVP và Supabase / BE sau này.
abstract interface class LeaderboardRepository {
  /// Lấy danh sách sân thi đấu có sẵn để chọn sân
  Future<List<Court>> getCourts();

  /// Lấy bảng xếp hạng của 1 sân cụ thể
  Future<List<PlayerProfile>> getCourtLeaderboard({
    required String courtId,
    int? limit,
  });

  /// Lấy danh sách vận động viên quanh vị trí của người dùng trong sân (±radius)
  Future<List<PlayerProfile>> getNearbyPlayers({
    required String courtId,
    required String playerId,
    int radius = 5,
  });

  /// Tính toán vị trí xếp hạng của người chơi trong sân được chọn
  Future<PlayerCourtRank?> getPlayerCourtRank({
    required String playerId,
    required String courtId,
  });

  /// Backward-compatibility helper for existing callers
  Future<List<PlayerProfile>> getLeaderboard({String? courtId});
}
