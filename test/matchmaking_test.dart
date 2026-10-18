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
  test('Vietnam recreational rank thresholds handle boundaries', () {
    expect(RankTier.values.length, 20);
    expect(RankTier.fromElo(0), RankTier.newbie);
    expect(RankTier.fromElo(300), RankTier.newbie);
    for (var i = 1; i < RankTier.values.length; i++) {
      final tier = RankTier.values[i];
      expect(RankTier.fromElo(tier.minimumElo - 1), RankTier.values[i - 1]);
      expect(RankTier.fromElo(tier.minimumElo), tier);
      expect(RankTier.values[i - 1].maximumElo, tier.minimumElo - 1);
    }
    expect(RankTier.fromElo(850), RankTier.intermediatePlus);
    expect(RankTier.fromElo(1000), RankTier.upperIntermediatePlus);
    expect(RankTier.fromElo(999999), RankTier.eliteAmateur);
    expect(RankTier.eliteAmateur.next, isNull);
    expect(() => RankTier.fromElo(-1), throwsArgumentError);
  });
}
