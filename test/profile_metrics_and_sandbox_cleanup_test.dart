import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/app/sport_xp_shell.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/data/mock_activity_repository.dart';
import 'package:sport_xp_4/features/feed/presentation/activity_feed_page.dart';
import 'package:sport_xp_4/features/profile/domain/player_profile.dart';
import 'package:sport_xp_4/features/profile/presentation/profile_page.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/presentation/managed_rooms_page.dart';

import 'managed_rooms_test.dart' show signedClient, response, userId;

void main() {
  group('Feedback 5: Thống nhất ý nghĩa các chỉ số hồ sơ', () {
    test('Tài khoản mới chưa có lịch sử có uy tín khởi tạo và 0/5 trận phân hạng', () {
      const profile = PlayerProfile(
        id: 'new-user',
        displayName: 'Người chơi mới',
        eloRating: 750,
        tierName: 'TB',
        trustScore: 100,
        winStreak: 3, // Thử chuỗi thắng > 0
        confirmedMatchesCount: 0, // Nhưng chưa có trận xác nhận nào
        isIdentityVerified: false,
      );

      // 1. Dựa trên số trận phân hạng đã xác nhận, độc lập với chuỗi thắng
      expect(profile.confirmedMatchesCount, 0);
      expect(profile.placementMatchesCompleted, 0);
      expect(profile.isCalibrated, isFalse);
      expect(profile.hasMatchHistory, isFalse);

      // 2. Với tài khoản mới: "Uy tín khởi tạo · chưa đủ lịch sử" thay vì "Uy tín tuyệt đối"
      expect(profile.trustStatusText, 'Uy tín khởi tạo · chưa đủ lịch sử');
    });

    test('Tài khoản đã có lịch sử thi đấu xác nhận đạt đủ phân hạng', () {
      const profile = PlayerProfile(
        id: 'veteran-user',
        displayName: 'Chiến binh',
        eloRating: 900,
        tierName: 'TB+',
        trustScore: 100,
        winStreak: 0,
        confirmedMatchesCount: 5,
        isIdentityVerified: true,
      );

      expect(profile.confirmedMatchesCount, 5);
      expect(profile.placementMatchesCompleted, 5);
      expect(profile.isCalibrated, isTrue);
      expect(profile.hasMatchHistory, isTrue);
      expect(profile.trustStatusText, 'Uy tín tuyệt đối');
    });

    testWidgets('Avatar không hiển thị tick xác minh nếu chưa KYC / chưa xác minh danh tính', (tester) async {
      const unverifiedProfile = PlayerProfile(
        id: 'unverified-user',
        displayName: 'Chưa xác minh',
        eloRating: 700,
        tierName: 'TBY+',
        trustScore: 100,
        winStreak: 0,
        confirmedMatchesCount: 0,
        isIdentityVerified: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ProfilePage(
              profile: Future.value(unverifiedProfile),
              isSignedIn: true,
              onSignOut: () {},
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Không hiển thị dấu tick verified
      expect(find.byIcon(Icons.verified), findsNothing);
      // Hiển thị uy tín khởi tạo
      expect(find.text('Uy tín khởi tạo · chưa đủ lịch sử'), findsOneWidget);
      // Hiển thị 0/5 trận phân hạng (độc lập với chuỗi thắng)
      expect(find.text('0/5 trận'), findsOneWidget);
    });

    testWidgets('Avatar hiển thị tick verified chỉ khi isIdentityVerified là true', (tester) async {
      const verifiedProfile = PlayerProfile(
        id: 'verified-user',
        displayName: 'Đã xác minh',
        eloRating: 1100,
        tierName: 'TBK+',
        trustScore: 98,
        winStreak: 2,
        confirmedMatchesCount: 8,
        isIdentityVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ProfilePage(
              profile: Future.value(verifiedProfile),
              isSignedIn: true,
              onSignOut: () {},
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.text('Uy tín tuyệt đối'), findsOneWidget);
    });
  });

  group('Feedback 6: Giảm công cụ thử nghiệm trên các màn chính', () {
    testWidgets('ActivityFeedPage không còn nút Kết nối giả lập trên header', (tester) async {
      final rooms = MockRoomRepository(userId: 'me');
      final repo = MockActivityRepository(rooms);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActivityFeedPage(
              repository: repo,
              rooms: rooms,
              refreshToken: 0,
              onFindRooms: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kết nối giả lập'), findsNothing);
    });

    testWidgets('ManagedRoomsPage không còn banner sandbox MockRoomControls', (tester) async {
      final rooms = MockRoomRepository(userId: 'me');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ManagedRoomsPage(
              repository: rooms,
              refreshToken: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MÔ PHỎNG DỮ LIỆU MVP (SANDBOX)'), findsNothing);
      expect(find.text('Chọn vai diễn trong phòng:'), findsNothing);
    });

    testWidgets('SportXpShell hiển thị nhãn vai nhỏ trên AppBar và gom công cụ vào Hồ sơ', (tester) async {
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          if (r.url.path.endsWith('/profiles')) {
            return response(r, {
              'id': userId,
              'display_name': 'Thanh Tùng',
              'elo_rating': 800,
              'tier_name': 'TB',
              'trust_score': 100,
              'win_streak': 0,
              'confirmed_matches_count': 0,
              'is_identity_verified': false,
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

      // 1. Nhãn nhỏ vai diễn hiện tại hiển thị ở AppBar
      expect(find.textContaining('Vai: Thanh Tùng'), findsOneWidget);

      // 2. Chuyển sang tab Hồ sơ
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();

      // 3. Khung "Chế độ thử nghiệm" được gom gọn trong Hồ sơ
      expect(find.text('CHẾ ĐỘ THỬ NGHIỆM'), findsOneWidget);
      expect(find.text('Đổi tài khoản giả lập'), findsOneWidget);
      expect(find.text('Kết nối giả lập'), findsOneWidget);
      expect(find.text('Đặt lại dữ liệu mô phỏng'), findsOneWidget);

      // Thử bấm mở Kết nối giả lập từ Hồ sơ
      await tester.tap(find.text('Kết nối giả lập'));
      await tester.pumpAndSettle();
      expect(find.text('KẾT NỐI BẠN BÈ GIẢ LẬP'), findsOneWidget);

      // Đóng modal
      await tester.tap(find.byType(SingleChildScrollView));
      Navigator.pop(tester.element(find.text('KẾT NỐI BẠN BÈ GIẢ LẬP')));
      await tester.pumpAndSettle();

      // Thử bấm Đặt lại dữ liệu mô phỏng
      await tester.tap(find.text('Đặt lại dữ liệu mô phỏng'));
      await tester.pumpAndSettle();
      expect(find.text('Đã đặt lại dữ liệu mô phỏng trong RAM.'), findsOneWidget);
    });
  });
}
