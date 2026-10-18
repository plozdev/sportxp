import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/features/profile/domain/player_profile.dart';
import 'package:sport_xp_4/features/rankings/domain/rank_tier.dart';

void main() {
  PlayerProfile player(int? elo, {String staleLabel = 'Phong trào Khá'}) =>
      PlayerProfile(
        id: 'p',
        displayName: 'Minh',
        eloRating: elo,
        tierName: staleLabel,
        trustScore: 100,
        winStreak: 0,
      );

  test('Profile and next target use the same fine-grained taxonomy', () {
    for (final tier in RankTier.values) {
      final profile = player(tier.minimumElo);
      expect(profile.tierName, tier.label);
      expect(profile.backendTierName, 'Phong trào Khá');
      if (tier.next case final next?) {
        expect(profile.nextTierProgress.nextTier, next.label);
        expect(profile.nextTierProgress.targetElo, next.minimumElo);
        expect(profile.nextTierProgress.progress, 0);
        expect(player(next.minimumElo - 1).nextTierProgress.pointsNeeded, 1);
      } else {
        expect(profile.nextTierProgress.pointsNeeded, 0);
        expect(profile.nextTierProgress.progress, 1);
      }
    }
  });

  test(
    '800..899 is TB+; 850 is provisional TB+, never an automatic semi-pro',
    () {
      expect(player(799).tierName, 'TB');
      expect(player(800).tierName, 'TB+');
      expect(player(850).tierName, 'TB+');
      expect(player(899).nextTierProgress.pointsNeeded, 1);
      expect(player(900).tierName, 'TBK-');
      expect(player(1000).tierName, 'TBK+');
      expect(player(null).tierName, 'Chưa xếp hạng');
      expect(
        RankTier.values.any((tier) => tier.label.contains('chuyên')),
        false,
      );
    },
  );

  test('Groups remain ordered, nonempty and contain their subtiers', () {
    expect(
      RankTier.values.map((tier) => tier.group).toSet(),
      RankGroup.values.toSet(),
    );
    var group = 0;
    for (final tier in RankTier.values) {
      expect(tier.group.index, greaterThanOrEqualTo(group));
      group = tier.group.index;
      expect(tier.description, isNotEmpty);
    }
  });
}
