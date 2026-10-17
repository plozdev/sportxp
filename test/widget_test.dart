import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/app/sport_xp_app.dart';

void main() {
  testWidgets('Create and join rooms through the shell', (tester) async {
    await tester.pumpWidget(const SportXpApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kèo đấu'));
    await tester.pumpAndSettle();
    expect(find.text('CÒN 1 CHỖ'), findsOneWidget);
    await tester.tap(find.text('VÀO KÈO'));
    await tester.pumpAndSettle();
    expect(find.text('ĐÃ THAM GIA'), findsOneWidget);
    expect(find.text('CÒN 0 CHỖ'), findsOneWidget);
    await tester.tap(find.text('TẠO KÈO MỚI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TẠO KÈO'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập tên sân ít nhất 3 ký tự.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Sân Phú Thọ');
    await tester.tap(find.text('TẠO KÈO'));
    await tester.pumpAndSettle();
    expect(find.text('Sân Phú Thọ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small screen and large text keep navigation usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SportXpApp());
    await tester.pumpAndSettle();
    for (final label in ['Kèo đấu', 'Giải đấu', 'Hồ sơ', 'Trang chủ']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
