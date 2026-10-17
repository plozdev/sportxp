import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/app/sport_xp_app.dart';

void main() {
  testWidgets('Missing config keeps four dark tabs usable at 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const SportXpApp(startupError: 'Chưa cấu hình Supabase.'),
    );
    await tester.pumpAndSettle();
    for (final label in ['Kèo đấu', 'Xếp hạng', 'Hồ sơ', 'Trang chủ']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text('BẢN DEMO'), findsNothing);
  });

  testWidgets(
    'Create requires auth and leaderboard loads real response values',
    (tester) async {
      final requests = <http.Request>[];
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-test-key',
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode([
                {
                  'id': 'player-1',
                  'display_name': 'Minh',
                  'elo_rating': 1550,
                  'tier_name': 'Vàng',
                  'trust_score': 99,
                  'win_streak': 5,
                },
              ]),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      ))!;
      addTearDown(() async => tester.runAsync(client.dispose));
      await tester.pumpWidget(SportXpApp(client: client));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TẠO KÈO MỚI'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xếp hạng'));
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
      expect(find.text('1550'), findsOneWidget);
      expect(
        requests.any(
          (r) =>
              r.url.queryParameters['order'] ==
              'elo_rating.desc.nullslast,id.asc.nullslast',
        ),
        true,
      );
      expect(requests.every((r) => r.method == 'GET'), true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
