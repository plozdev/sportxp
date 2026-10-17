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
    expect(RankTier.fromElo(449), RankTier.newbie);
    expect(RankTier.fromElo(450), RankTier.lowerCasual);
    expect(RankTier.fromElo(599), RankTier.lowerCasual);
    expect(RankTier.fromElo(600), RankTier.midCasual);
    expect(RankTier.fromElo(749), RankTier.midCasual);
    expect(RankTier.fromElo(750), RankTier.upperCasual);
    expect(RankTier.fromElo(999), RankTier.upperCasual);
    expect(RankTier.fromElo(1000), RankTier.advanced);
    expect(() => RankTier.fromElo(-1), throwsArgumentError);
  });
}
