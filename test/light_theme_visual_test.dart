import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/data/mock_activity_repository.dart';
import 'package:sport_xp_4/features/feed/presentation/activity_feed_page.dart';
import 'package:sport_xp_4/features/profile/domain/player_profile.dart';
import 'package:sport_xp_4/features/profile/presentation/profile_page.dart';
import 'package:sport_xp_4/features/rankings/data/mock_leaderboard_repository.dart';
import 'package:sport_xp_4/features/rankings/presentation/leaderboard_page.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/presentation/managed_rooms_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!const bool.fromEnvironment('TEST_SDK_FONTS', defaultValue: true)) {
      return;
    }
    try {
      final sdk =
          Platform.environment['FLUTTER_ROOT'] ??
          File(Platform.resolvedExecutable)
              .parent
              .parent
              .parent
              .parent
              .parent
              .parent
              .path;
      final dir = Directory('$sdk/bin/cache/artifacts/material_fonts');
      if (dir.existsSync()) {
        final loader = FontLoader('Roboto');
        var loadedRoboto = false;
        for (final weight in ['regular', 'medium', 'bold', 'black']) {
          File file = File('${dir.path}/roboto-$weight.ttf');
          if (!file.existsSync()) {
            file = File('${dir.path}/Roboto-$weight.ttf');
          }
          if (file.existsSync()) {
            loader.addFont(file.readAsBytes().then(ByteData.sublistView));
            loadedRoboto = true;
          }
        }
        if (loadedRoboto) {
          await loader.load();
        }

        File iconsFile = File('${dir.path}/materialicons-regular.otf');
        if (!iconsFile.existsSync()) {
          iconsFile = File('${dir.path}/MaterialIcons-Regular.otf');
        }
        if (iconsFile.existsSync()) {
          await (FontLoader('MaterialIcons')
                ..addFont(iconsFile.readAsBytes().then(ByteData.sublistView)))
              .load();
        }
      }
    } catch (_) {
      // Font artifacts may not be cached in headless CI environments.
    }
  });

  for (final screen in ['feed', 'rooms', 'rankings', 'profile']) {
    testWidgets('$screen uses light surfaces and fits compact phones', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rooms = MockRoomRepository(
        userId: 'preview',
        displayName: 'Hoàng Nguyễn',
      );
      final activities = MockActivityRepository(rooms);
      final rank = MockLeaderboardRepository(rooms);
      const player = PlayerProfile(
        id: 'preview',
        displayName: 'Hoàng Nguyễn',
        eloRating: 770,
        tierName: 'TB',
        trustScore: 98,
        winStreak: 4,
        confirmedMatchesCount: 12,
        homeCourtName: 'Sân Đào Duy Anh',
      );
      Widget page;
      switch (screen) {
        case 'feed':
          page = ActivityFeedPage(
            repository: activities,
            rooms: rooms,
            refreshToken: 0,
            onFindRooms: () {},
          );
        case 'rooms':
          page = ManagedRoomsPage(repository: rooms, refreshToken: 0);
        case 'rankings':
          page = LeaderboardPage(
            repository: rank,
            onRefresh: () {},
            isMock: true,
            selectedPlayerId: 'preview',
          );
        default:
          page = ProfilePage(
            profile: Future.value(player),
            isSignedIn: true,
            onSignOut: () {},
            onRefresh: () {},
            activityRepository: activities,
            roomRepository: rooms,
          );
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              appBar: AppBar(
                flexibleSpace: const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.headerGradient),
                ),
                title: const Text(
                  'SPORTXP',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              body: page,
              bottomNavigationBar: NavigationBar(
                selectedIndex: [
                  'feed',
                  'rooms',
                  'rankings',
                  'profile',
                ].indexOf(screen),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sports_tennis),
                    label: 'Kèo đấu',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    label: 'Xếp hạng',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Hồ sơ',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/light-theme-previews/$screen.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      tester.view.physicalSize = const Size(320, 740);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView).first, const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
