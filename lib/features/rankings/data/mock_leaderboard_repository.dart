import '../../matchmaking/domain/court.dart';
import '../../profile/domain/player_profile.dart';
import '../../rooms/data/mock_room_repository.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/rank_tier.dart';

/// Mock repository cho MVP, hỗ trợ mô phỏng hàng chục/hàng trăm người chơi trên từng sân.
class MockLeaderboardRepository implements LeaderboardRepository {
  const MockLeaderboardRepository(this.sandbox);
  final MockRoomRepository sandbox;

  /// Tương thích với test cũ và sandbox identity
  List<PlayerProfile> players() {
    const streaks = {'linh': 4, 'minh': 2, 'an': 0, 'bao': 6};
    const matchCounts = {'linh': 8, 'minh': 5, 'an': 0, 'bao': 12};
    final rows =
        [
          for (final person in sandbox.people.entries)
            PlayerProfile(
              id: person.key,
              displayName: person.value,
              eloRating: sandbox.ratings[person.key] ?? 750,
              tierName: '',
              trustScore: 100,
              winStreak: streaks[person.key] ?? 0,
              confirmedMatchesCount: matchCounts[person.key] ?? 0,
              homeCourtId: _courtForPlayer(person.key),
              homeCourtName: _courtNameForPlayer(person.key),
            ),
        ]..sort((a, b) {
          final order = (b.eloRating ?? 0).compareTo(a.eloRating ?? 0);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });
    return rows;
  }

  static String _courtForPlayer(String playerId) {
    switch (playerId) {
      case 'bao':
      case 'linh':
        return 'court-a';
      case 'minh':
        return 'court-b';
      case 'an':
        return 'court-c';
      default:
        return 'court-a';
    }
  }

  static String _courtNameForPlayer(String playerId) {
    switch (playerId) {
      case 'bao':
      case 'linh':
        return 'Sân Đào Duy Anh';
      case 'minh':
        return 'Sân Bình Thạnh';
      case 'an':
        return 'Sân Thủ Đức';
      default:
        return 'Sân Đào Duy Anh';
    }
  }

  @override
  Future<List<Court>> getCourts() async {
    return [
      const Court(id: 'court-a', name: 'Sân Đào Duy Anh', distanceKm: 1.8),
      const Court(id: 'court-b', name: 'Sân Bình Thạnh', distanceKm: 4.2),
      const Court(id: 'court-c', name: 'Sân Thủ Đức', distanceKm: 8.5),
    ];
  }

  static const List<(String, int, int)> _clubMembersSeed = [
    ('Hoàng Long', 960, 5),
    ('Trần Dũng', 930, 3),
    ('Phạm Hùng', 900, 2),
    ('Lê Nam', 880, 4),
    ('Vũ Huy', 850, 1),
    ('Đức Thịnh', 830, 0),
    ('Thanh Tùng', 810, 2),
    ('Việt Anh', 790, 3),
    ('Ngọc Sơn', 770, 1),
    ('Tuấn Anh', 750, 0),
    ('Minh Trí', 730, 2),
    ('Hữu Đạt', 710, 1),
    ('Quang Khải', 690, 0),
    ('Trung Kiên', 670, 2),
    ('Thành Đạt', 650, 0),
    ('Duy Mạnh', 630, 1),
    ('Tiến Dũng', 610, 0),
    ('Xuân Trường', 590, 2),
    ('Công Phượng', 570, 0),
    ('Hùng Dũng', 550, 1),
    ('Văn Hậu', 530, 0),
    ('Hoàng Đức', 510, 1),
    ('Quang Hải', 490, 0),
    ('Văn Toàn', 470, 0),
    ('Tấn Tài', 450, 1),
    ('Đức Huy', 430, 0),
    ('Bùi Dũng', 410, 0),
    ('Hồng Duy', 390, 0),
    ('Văn Thanh', 370, 0),
    ('Trọng Hoàng', 350, 0),
  ];

  List<PlayerProfile> _generateCourtPlayers(String courtId) {
    final courtName = courtId == 'court-b'
        ? 'Sân Bình Thạnh'
        : courtId == 'court-c'
        ? 'Sân Thủ Đức'
        : 'Sân Đào Duy Anh';

    // 1. Lấy người chơi từ sandbox thuộc sân hoặc người dùng hiện tại
    final sandboxRows = players();
    final matchedSandbox = sandboxRows
        .where((p) => p.homeCourtId == courtId || p.id == sandbox.actorId)
        .toList();

    // 2. Thêm danh sách hội viên câu lạc bộ sân để mô phỏng hàng chục người
    final clubList = <PlayerProfile>[
      ...matchedSandbox,
      for (var i = 0; i < _clubMembersSeed.length; i++)
        PlayerProfile(
          id: 'member-$courtId-$i',
          displayName: _clubMembersSeed[i].$1,
          eloRating: _clubMembersSeed[i].$2,
          tierName: '',
          trustScore: 95 + (i % 5),
          winStreak: _clubMembersSeed[i].$3,
          confirmedMatchesCount: 10 + i,
          homeCourtId: courtId,
          homeCourtName: courtName,
        ),
    ];

    // Loại bỏ trùng lặp và sắp xếp theo Elo giảm dần
    final seenIds = <String>{};
    final uniqueList = <PlayerProfile>[];
    for (final p in clubList) {
      if (seenIds.add(p.id)) {
        uniqueList.add(p);
      }
    }

    uniqueList.sort((a, b) {
      final order = (b.eloRating ?? 0).compareTo(a.eloRating ?? 0);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });

    return uniqueList;
  }

  @override
  Future<List<PlayerProfile>> getCourtLeaderboard({
    required String courtId,
    int? limit,
  }) async {
    final list = _generateCourtPlayers(courtId);
    if (limit != null && limit > 0) {
      return list.take(limit).toList();
    }
    return list;
  }

  @override
  Future<List<PlayerProfile>> getNearbyPlayers({
    required String courtId,
    required String playerId,
    int radius = 5,
  }) async {
    final list = _generateCourtPlayers(courtId);
    final index = list.indexWhere((p) => p.id == playerId);
    if (index == -1) {
      return list.take(radius * 2 + 1).toList();
    }
    final start = (index - radius).clamp(0, list.length);
    final end = (index + radius + 1).clamp(0, list.length);
    return list.sublist(start, end);
  }

  @override
  Future<PlayerCourtRank?> getPlayerCourtRank({
    required String playerId,
    required String courtId,
  }) async {
    final list = _generateCourtPlayers(courtId);
    final index = list.indexWhere((p) => p.id == playerId);
    if (index == -1) return null;

    final player = list[index];
    final rank = index + 1;
    final total = list.length;

    int? pointsToNext;
    String? nextName;
    if (index > 0) {
      final above = list[index - 1];
      pointsToNext = ((above.eloRating ?? 0) - (player.eloRating ?? 0)).abs() + 1;
      nextName = above.displayName;
    }

    final courtName = courtId == 'court-b'
        ? 'Sân Bình Thạnh'
        : courtId == 'court-c'
        ? 'Sân Thủ Đức'
        : 'Sân Đào Duy Anh';

    return PlayerCourtRank(
      rank: rank,
      totalPlayers: total,
      courtName: courtName,
      courtId: courtId,
      pointsToNextRank: pointsToNext,
      nextPlayerName: nextName,
      isPodium: rank <= 3,
      tier: player.eloRating != null ? RankTier.fromElo(player.eloRating!) : null,
      elo: player.eloRating,
    );
  }

  @override
  Future<List<PlayerProfile>> getLeaderboard({String? courtId}) async {
    return getCourtLeaderboard(courtId: courtId ?? 'court-a');
  }
}
