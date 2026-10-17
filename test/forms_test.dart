import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/domain/match_draft.dart';
import 'package:sport_xp_4/features/feed/presentation/record_match_sheet.dart';
import 'package:sport_xp_4/features/matchmaking/domain/court.dart';
import 'package:sport_xp_4/features/matchmaking/domain/create_room_draft.dart';
import 'package:sport_xp_4/features/matchmaking/presentation/create_match_sheet.dart';

Widget host(Widget sheet) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => sheet,
        ),
        child: const Text('Open'),
      ),
    ),
  ),
);

void main() {
  test('Score validation accepts completed badminton sets', () {
    for (final value in ['21-19 21-16', '22-20', '30-29', '30–28']) {
      expect(MatchDraft.validateScore(value), isNull);
    }
    for (final value in [
      '',
      '21-21',
      '20-18',
      '31-29',
      '22-19',
      '30-27',
      'hello',
    ]) {
      expect(MatchDraft.validateScore(value), isNotNull);
    }
  });
  testWidgets('Record form submits validated values with loss selection', (
    tester,
  ) async {
    MatchDraft? submitted;
    await tester.pumpWidget(
      host(
        RecordMatchSheet(
          onSubmit: (draft) async {
            submitted = draft;
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Sân A');
    await tester.enterText(fields.at(1), 'An & Bình');
    await tester.enterText(fields.at(2), 'Chi & Dũng');
    await tester.enterText(fields.at(3), '19-21 16-21');
    await tester.ensureVisible(find.text('Thua'));
    await tester.tap(find.text('Thua'));
    await tester.pump();
    await tester.ensureVisible(find.text('LƯU KẾT QUẢ'));
    await tester.tap(find.text('LƯU KẾT QUẢ'));
    await tester.pumpAndSettle();
    expect(submitted?.isWin, false);
    expect(submitted?.courtName, 'Sân A');
    expect(submitted?.score, '19-21 16-21');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Room form uses court IDs and default four slots', (
    tester,
  ) async {
    CreateRoomDraft? submitted;
    await tester.pumpWidget(
      host(
        CreateMatchSheet(
          loadCourts: () async => [const Court(id: 'court-1', name: 'Sân A')],
          onSubmit: (draft) async {
            submitted = draft;
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sân A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('TẠO KÈO'));
    await tester.pumpAndSettle();
    expect(submitted?.courtId, 'court-1');
    expect(submitted?.maxSlots, 4);
    expect(submitted!.startsAt.isAfter(DateTime.now()), true);
  });
}
