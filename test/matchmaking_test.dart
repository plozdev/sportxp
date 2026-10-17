import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/features/matchmaking/data/in_memory_match_repository.dart';
import 'package:sport_xp_4/features/rankings/domain/rank_tier.dart';

void main() {
  test('Joining is idempotent and cannot overbook', () async {
    final repo = InMemoryMatchRepository();
    final room = (await repo.listRooms()).single;
    expect((await repo.joinRoom(room.id, 'me')).availableSlots, 0);
    expect((await repo.joinRoom(room.id, 'me')).availableSlots, 0);
    await expectLater(repo.joinRoom(room.id, 'another'), throwsStateError);
    expect(() => room.playerIds.add('mutation'), throwsUnsupportedError);
  });
  test('Reject past starts and missing rooms', () async {
    final repo = InMemoryMatchRepository();
    await expectLater(
      repo.createRoom(
        courtName: 'Court',
        startsAt: DateTime.now().subtract(const Duration(hours: 1)),
        hostId: 'me',
      ),
      throwsArgumentError,
    );
    await expectLater(repo.joinRoom('missing', 'me'), throwsStateError);
  });
  test('Provisional rank thresholds handle boundaries', () {
    expect(RankTier.fromElo(999), RankTier.bronze);
    expect(RankTier.fromElo(1000), RankTier.silver);
    expect(RankTier.fromElo(1400), RankTier.gold);
    expect(RankTier.fromElo(1800), RankTier.platinum);
    expect(() => RankTier.fromElo(-1), throwsArgumentError);
  });
}
