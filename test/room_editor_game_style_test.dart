import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/domain/managed_room.dart';
import 'package:sport_xp_4/features/rooms/presentation/managed_rooms_page.dart';
import 'package:sport_xp_4/features/rooms/presentation/room_editor_page.dart';

void main() {
  testWidgets(
    'RoomEditorPage displays game lobby code hero banner with copy and regenerate',
    (tester) async {
      final repo = MockRoomRepository(userId: '00000000-0000-4000-8000-000000000001');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RoomEditorPage(
              repository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Game Lobby Banner
      expect(find.text('SẢNH PHÒNG THI ĐẤU'), findsOneWidget);
      expect(find.text('MÃ PHÒNG (ROOM CODE)'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsWidgets);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Verify Public & Private cards
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('PHÒNG CÔNG KHAI'), findsOneWidget);

      // Tap Private card
      await tester.tap(find.text('Private'));
      await tester.pumpAndSettle();
      expect(find.text('PHÒNG KÍN'), findsOneWidget);
      expect(find.textContaining('không cần kết bạn'), findsOneWidget);

      // Tap Public card
      await tester.tap(find.text('Public'));
      await tester.pumpAndSettle();
      expect(find.text('PHÒNG CÔNG KHAI'), findsOneWidget);

      // Verify Capacity Stepper
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets);

      // Verify Rank Presets
      expect(find.text('Mọi trình'), findsOneWidget);
      expect(find.text('TB - TBK'), findsOneWidget);
      await tester.ensureVisible(find.text('TB - TBK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TB - TBK'));
      await tester.pumpAndSettle();

      // Select court
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      final courts = await repo.courts();
      await tester.tap(find.text(courts.first.name).last);
      await tester.pumpAndSettle();

      // Switch to Private
      await tester.ensureVisible(find.text('Private'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private'));
      await tester.pumpAndSettle();

      // Save room
      await tester.ensureVisible(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ManagedRoomsPage renders 3-tab game lobby, join by code modal, and streamlined cards',
    (tester) async {
      final repo = MockRoomRepository(userId: '00000000-0000-4000-8000-000000000001');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ManagedRoomsPage(
              repository: repo,
              refreshToken: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify top lobby bar
      expect(find.text('SẢNH KÈO ĐẤU'), findsOneWidget);
      expect(find.text('Nhập mã'), findsOneWidget);

      // Verify 3 tabs
      expect(find.text('Sảnh Public'), findsOneWidget);
      expect(find.text('Phòng Private'), findsOneWidget);
      expect(find.text('Buổi của tôi'), findsOneWidget);

      // Open Join by Code modal
      await tester.tap(find.text('Nhập mã'));
      await tester.pumpAndSettle();
      expect(find.text('VÀO PHÒNG BẰNG MÃ'), findsOneWidget);
      expect(find.text('VÀO PHÒNG NGAY'), findsOneWidget);

      // Close modal
      Navigator.of(tester.element(find.text('VÀO PHÒNG BẰNG MÃ'))).pop();
      await tester.pumpAndSettle();

      // Switch to Phòng Private
      await tester.tap(find.text('Phòng Private'));
      await tester.pumpAndSettle();
      expect(find.text('Phòng riêng bằng mã'), findsWidgets);

      // Switch to Buổi của tôi
      await tester.tap(find.text('Buổi của tôi'));
      await tester.pumpAndSettle();
      expect(find.text('Sắp tới'), findsOneWidget);
      expect(find.text('Lịch sử'), findsOneWidget);
    },
  );

  test('ManagedRoom exposes roomCode properly from json or fallback', () {
    final customRoom = ManagedRoom.fromJson({
      'id': '22222222-2222-4222-8222-222222222222',
      'court_id': '11111111-1111-4111-8111-111111111111',
      'title': 'Trận đấu Rank',
      'court_name': 'Sân A',
      'starts_at': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      'ends_at': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'cancel_by': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'capacity': 6,
      'reserved': 3,
      'min_elo': 600,
      'max_elo': 1200,
      'fee': 50000,
      'revision': 1,
      'visibility': 'PRIVATE',
      'status': 'OPEN',
      'host_plays': true,
      'is_host': true,
      'host_name': 'Hoàng',
      'room_code': '#XP-7777',
    });

    expect(customRoom.roomCode, '#XP-7777');
    expect(customRoom.editableTerms['room_code'], '#XP-7777');

    final fallbackRoom = ManagedRoom.fromJson({
      'id': 'abcd1234-5678',
      'court_id': '11111111-1111-4111-8111-111111111111',
      'title': 'Trận đấu Kèo',
      'court_name': 'Sân B',
      'starts_at': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      'ends_at': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      'cancel_by': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'capacity': 4,
      'reserved': 2,
      'min_elo': 0,
      'max_elo': 2000,
      'fee': 40000,
      'revision': 1,
      'visibility': 'PUBLIC',
      'status': 'OPEN',
      'host_plays': false,
      'is_host': false,
      'host_name': 'An',
    });

    expect(fallbackRoom.roomCode, '#XP-ABCD');
  });

  testWidgets(
    'Notices banner in ManagedRoomsPage expands ListTile without DecoratedBox assertions',
    (tester) async {
      final repo = MockRoomRepository(userId: '00000000-0000-4000-8000-000000000001');
      final room = (await repo.get('host-demo'))!;
      await repo.execute(
        RoomCommand(
          'edit',
          roomId: 'host-demo',
          payload: {...room.editableTerms, 'fee': 45000},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ManagedRoomsPage(
              repository: repo,
              refreshToken: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find notices banner and expand it
      expect(find.textContaining('thông báo buổi chơi mới'), findsOneWidget);
      await tester.tap(find.textContaining('thông báo buổi chơi mới'));
      await tester.pumpAndSettle();

      // Verify ListTile is displayed and no Flutter framework assertion is thrown
      expect(find.byType(ListTile), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
