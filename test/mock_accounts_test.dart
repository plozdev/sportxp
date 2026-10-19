import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/app/sport_xp_shell.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/rankings/data/mock_leaderboard_repository.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/feed/presentation/activity_feed_page.dart';
import 'package:sport_xp_4/features/rankings/presentation/leaderboard_page.dart';

import 'managed_rooms_test.dart' show signedClient, response, userId;

void main() {
  test('Leaderboard shares all sandbox identities and initial ratings, sorted with stable ties', () {
    final rooms = MockRoomRepository(userId: 'me');
    rooms.updateProfile('Tên thật', 850);
    final leaderboard = MockLeaderboardRepository(rooms);
    final rows = leaderboard.players();
    expect(rows.map((p) => p.id).toSet(), rooms.people.keys.toSet());
    expect(rows.map((p) => p.eloRating), [1000, 850, 800, 750, 700]);
    expect(rows.first.id, 'bao');
    expect(rows[1].displayName, 'Tên thật');
    rooms.selectActor('linh');
    expect(leaderboard.players().map((p) => p.id), rows.map((p) => p.id));
  });
  testWidgets(
    'Profile switches shared mock actor; Auth and real profile stay unchanged; leaderboard is mocked',
    (tester) async {
      final queries = <Map<String, String>>[];
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          if (r.url.path.endsWith('/profiles')) {
            queries.add(r.url.queryParameters);
            return response(r, {
              'id': userId,
              'display_name': 'Hồ sơ thật',
              'elo_rating': 850,
              'tier_name': 'TB+',
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
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi tài khoản giả lập'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-linh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đang thử: Linh'), findsOneWidget);
      expect(client.auth.currentUser!.id, userId);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(find.byType(ActivityFeedPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Xếp hạng'));
      await tester.pumpAndSettle();
      expect(find.textContaining('BẢNG XẾP HẠNG GIẢ LẬP'), findsOneWidget);
      final page = tester.widget<LeaderboardPage>(find.byType(LeaderboardPage));
      expect(page.selectedPlayerId, 'linh');
      expect(page.repository, isA<MockLeaderboardRepository>());
      expect(
        queries.every((q) => q.containsKey('id')),
        true,
      ); // no real leaderboard query
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('ROOMS_MOCK_ENABLED', defaultValue: true),
  );
  testWidgets(
    'Account selector stays available even if real profile is unavailable',
    (tester) async {
      final client = (await tester.runAsync(
        () => signedClient((r) async => response(r, null)),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: SportXpShell(client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đổi tài khoản giả lập'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-minh')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('ROOMS_MOCK_ENABLED', defaultValue: true),
  );
}
