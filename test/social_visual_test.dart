import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/profile/domain/player_profile.dart';
import 'package:sport_xp_4/features/profile/presentation/widgets/passport_sheet.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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
  testWidgets('Real passport QR fits small phones at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final key = GlobalKey();
    const player = PlayerProfile(
      id: 'private-auth-id',
      publicId: '00000000-0000-4000-8000-000000000001',
      displayName: 'Hoàng Nguyễn',
      eloRating: 750,
      tierName: 'TB',
      trustScore: 100,
      winStreak: 3,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
        ),
        home: RepaintBoundary(
          key: key,
          child: const Scaffold(body: PassportSheet(profile: player)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    final link = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .data!;
    expect(link, contains(player.publicId!));
    expect(link, isNot(contains(player.id)));
    expect(find.textContaining('Đã tạo ảnh'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/social-previews/passport.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('SAO CHÉP LINK'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
