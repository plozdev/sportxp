import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/rankings/data/mock_leaderboard_repository.dart';
import 'package:sport_xp_4/features/rankings/domain/leaderboard_repository.dart';
import 'package:sport_xp_4/features/rankings/presentation/leaderboard_page.dart';
import 'package:sport_xp_4/features/rankings/presentation/widgets/court_picker_sheet.dart';
import 'package:sport_xp_4/features/rankings/presentation/widgets/duolingo_rank_row.dart';
import 'package:sport_xp_4/features/rankings/presentation/widgets/my_fixed_standing_bar.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';

void main() {
  group('LeaderboardRepository & Mock Implementation', () {
    test('MockLeaderboardRepository generates rich court players and nearby window', () async {
      final sandbox = MockRoomRepository(userId: 'user-1', displayName: 'Tuấn');
      final repo = MockLeaderboardRepository(sandbox);

      final courts = await repo.getCourts();
      expect(courts.length, 3);
      expect(courts.first.id, 'court-a');
      expect(courts.first.name, 'Sân Đào Duy Anh');

      final courtAPlayers = await repo.getCourtLeaderboard(courtId: 'court-a');
      expect(courtAPlayers.length, greaterThan(20));
      expect(courtAPlayers.any((p) => p.displayName == 'Bảo · giả lập'), true);

      final nearby = await repo.getNearbyPlayers(
        courtId: 'court-a',
        playerId: 'user-1',
        radius: 5,
      );
      expect(nearby.length, lessThanOrEqualTo(11));
      expect(nearby.any((p) => p.id == 'user-1'), true);

      final rank = await repo.getPlayerCourtRank(
        playerId: 'user-1',
        courtId: 'court-a',
      );
      expect(rank, isNotNull);
      expect(rank!.totalPlayers, courtAPlayers.length);
      expect(rank.courtName, 'Sân Đào Duy Anh');
    });
  });

  group('LeaderboardPage Duolingo UI & Court Selection', () {
    testWidgets('renders explicit court header, promotion line, and dedicated bottom bar', (tester) async {
      final sandbox = MockRoomRepository(userId: 'user-1', displayName: 'Tuấn');
      final repo = MockLeaderboardRepository(sandbox);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LeaderboardPage(
              repository: repo,
              onRefresh: () {},
              isMock: true,
              selectedPlayerId: 'user-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check explicit court header & mock notice
      expect(find.text('BẢNG XẾP HẠNG THEO SÂN'), findsOneWidget);
      expect(find.text('Sân Đào Duy Anh'), findsOneWidget);
      expect(find.textContaining('BẢNG XẾP HẠNG GIẢ LẬP'), findsOneWidget);

      // Check Duolingo Mode Tabs
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Quanh bạn (±5)'), findsOneWidget);

      // Check Duolingo Promotion line
      expect(find.text('KHU VỰC THĂNG HẠNG (TOP 3)'), findsOneWidget);

      // Check rows rendered
      expect(find.byType(DuolingoRankRow), findsWidgets);
      expect(find.text('Bảo · giả lập'), findsWidgets);

      // Check dedicated fixed standing bar at the bottom
      expect(find.byType(MyFixedStandingBar), findsOneWidget);
      expect(find.textContaining('VỊ TRÍ CỦA BẠN TẠI'), findsOneWidget);

      // Switch to "Quanh bạn (±5)"
      await tester.tap(find.text('Quanh bạn (±5)'));
      await tester.pumpAndSettle();

      // In nearMe mode, current user is displayed
      expect(find.text('Tuấn'), findsWidgets);

      // Tap court picker button to open CourtPickerSheet
      await tester.tap(find.byKey(const Key('court_picker_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CourtPickerSheet), findsOneWidget);
      expect(find.text('CHỌN SÂN XẾP HẠNG'), findsOneWidget);

      // Select Sân Bình Thạnh
      await tester.tap(find.text('Sân Bình Thạnh'));
      await tester.pumpAndSettle();

      expect(find.text('Sân Bình Thạnh'), findsOneWidget);

      // Tap a player row to open PlayerDetailModal
      await tester.tap(find.byType(DuolingoRankRow).first);
      await tester.pumpAndSettle();

      expect(find.text('ĐIỂM ELO'), findsOneWidget);
      expect(find.text('UY TÍN'), findsOneWidget);
    });

    testWidgets('MyFixedStandingBar renders and triggers scroll callback', (tester) async {
      var jumped = false;
      final sandbox = MockRoomRepository(userId: 'user-1', displayName: 'Tuấn');
      final profile = (MockLeaderboardRepository(sandbox).players().first);
      const rankInfo = PlayerCourtRank(
        rank: 14,
        totalPlayers: 35,
        courtName: 'Sân Đào Duy Anh',
        courtId: 'court-a',
        pointsToNextRank: 20,
        nextPlayerName: 'Linh',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MyFixedStandingBar(
              userProfile: profile,
              rankSummary: rankInfo,
              onScrollToMyRank: () {
                jumped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('#14'), findsOneWidget);
      expect(find.textContaining('VỊ TRÍ CỦA BẠN TẠI'), findsOneWidget);

      await tester.tap(find.byKey(const Key('my_fixed_standing_row')));
      expect(jumped, true);
    });
  });
}
