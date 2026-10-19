import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/app/sport_xp_shell.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/data/mock_activity_repository.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';
import 'package:sport_xp_4/features/rankings/presentation/leaderboard_page.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/presentation/managed_rooms_page.dart';

import 'managed_rooms_test.dart' show signedClient, response, userId;

void main() {
  test('Demo feed seeds on first open and reset; all routes share content and preserve privacy', () async {
    final rooms = MockRoomRepository(userId: 'me');
    final home = MockActivityRepository(rooms);
    final posts = await home.list();
    expect(posts, isNotEmpty);
    final initialIds = posts.map((post) => post.id).toSet();
    expect(initialIds.length, posts.length);
    expect(posts.map((p) => p.authorId).toSet(), {
      'me',
      'linh',
      'minh',
      'an',
      'bao',
    });
    expect(posts.any((p) => p.totals.pending > 0), true);
    expect(
      (await home.drafts()).any((p) => p.roomId == 'room-user-draft'),
      true,
    );
    final fromRoom = MockActivityRepository(rooms);
    expect(identical(home, fromRoom), true);
    final mine = posts.firstWhere(
      (p) => p.authorId == 'me' && p.audience == ActivityAudience.friends,
    );
    await fromRoom.execute(
      ActivityCommand(
        'save',
        activityId: mine.id,
        expectedVersion: mine.version,
        caption: 'Chia sẻ từ buổi chơi',
        audience: mine.audience,
      ),
    );
    expect((await home.get(mine.id))!.caption, 'Chia sẻ từ buổi chơi');
    rooms.selectActor('linh');
    expect(
      (await home.list()).any(
        (p) => p.audience == ActivityAudience.onlyMe && p.authorId == 'me',
      ),
      false,
    );
    rooms.reset();
    expect((await home.list()).map((post) => post.id).toSet(), initialIds);
    rooms.setMockFriend('minh', false);
    expect((await home.list()).any((p) => p.authorId == 'minh'), false);
  });
  testWidgets(
    'Scrolling rankings keeps data, position, Auth reads and room FAB stable',
    (tester) async {
      var profileReads = 0;
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          if (r.url.path.endsWith('/profiles')) {
            profileReads++;
            return response(r, {
              'id': userId,
              'display_name': 'Hoàng',
              'elo_rating': 700,
              'tier_name': 'TB-',
              'trust_score': 100,
              'win_streak': 0,
            });
          }
          return response(r, []);
        }),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: SportXpShell(client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xếp hạng'));
      await tester.pumpAndSettle();
      final list = find
          .descendant(
            of: find.byType(LeaderboardPage),
            matching: find.byType(ListView),
          )
          .first;
      final controller = tester.widget<ListView>(list).controller!;
      final repository = tester
          .widget<LeaderboardPage>(find.byType(LeaderboardPage))
          .repository;
      final reads = profileReads;
      await tester.drag(list, const Offset(0, -420));
      await tester.pumpAndSettle();
      final offset = controller.offset;
      expect(offset, greaterThan(200));
      await tester.drag(list, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(offset));
      expect(
        tester.widget<LeaderboardPage>(find.byType(LeaderboardPage)).repository,
        same(repository),
      );
      expect(profileReads, reads);
      await tester.tap(find.text('Kèo đấu'));
      await tester.pumpAndSettle();
      final rooms = find
          .descendant(
            of: find.byType(ManagedRoomsPage),
            matching: find.byType(ListView),
          )
          .first;
      await tester.drag(rooms, const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .isExtended,
        true,
      );
      await tester.drag(rooms, const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .isExtended,
        true,
      );
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      expect(profileReads, reads);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('ROOMS_MOCK_ENABLED', defaultValue: true),
  );
}
