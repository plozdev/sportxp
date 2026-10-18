import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/app/sport_xp_app.dart';

const userId = '00000000-0000-4000-8000-000000000002';
Map<String, dynamic> token() => {
  'access_token': 'test-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'refresh_token': 'refresh',
  'user': {
    'id': userId,
    'aud': 'authenticated',
    'email': 'b@example.com',
    'created_at': '2026-10-18T00:00:00Z',
    'app_metadata': {},
    'user_metadata': {},
  },
};
SupabaseClient clientFor(
  List<http.Request> calls, {
  bool missingProfile = false,
}) => SupabaseClient(
  'https://example.supabase.co',
  'public-test',
  authOptions: const AuthClientOptions(
    autoRefreshToken: false,
    authFlowType: AuthFlowType.implicit,
  ),
  httpClient: MockClient((r) async {
    calls.add(r);
    Object? body;
    final name = r.url.path.split('/').last;
    if (name == 'token') {
      body = token();
    } else if (name == 'get_onboarding_state') {
      body = {
        'onboarding_step': 5,
        'answers': [0, 0, 0, 0, 0],
        'display_name': 'B',
        'elo_rating': 750,
        'tier_name': 'TB',
      };
    } else if (name == 'profiles') {
      body = r.url.queryParameters.containsKey('id')
          ? (missingProfile
                ? null
                : {
                    'id': userId,
                    'display_name': 'B',
                    'elo_rating': 750,
                    'tier_name': 'TB',
                    'trust_score': 100,
                    'win_streak': 0,
                    'onboarding_step': 5,
                  })
          : [
              {
                'id': userId,
                'display_name': 'Minh',
                'elo_rating': 1550,
                'tier_name': 'Tốt',
                'trust_score': 99,
                'win_streak': 5,
              },
            ];
    }
    return http.Response(
      jsonEncode(body),
      200,
      request: r,
      headers: {'content-type': 'application/json'},
    );
  }),
);

void main() {
  testWidgets(
    'Missing configuration shows full auth screen and cannot enter the app at 200% text',
    (tester) async {
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
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      final button = find.widgetWithText(FilledButton, 'ĐĂNG NHẬP');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Guest cannot fetch protected data or bypass login with back', (
    tester,
  ) async {
    final calls = <http.Request>[];
    final client = (await tester.runAsync(() async => clientFor(calls)))!;
    addTearDown(() => tester.runAsync(client.dispose));
    await tester.pumpWidget(SportXpApp(client: client));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại.'), findsOneWidget);
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu lên sân.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byType(BottomSheet), findsNothing);
    expect(calls, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Login unlocks app; logout removes pushed screens and modal content',
    (tester) async {
      final calls = <http.Request>[];
      final client = (await tester.runAsync(() async => clientFor(calls)))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(SportXpApp(client: client));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'b@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'ĐĂNG NHẬP'));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Chào mừng trở lại.'), findsNothing);
      await tester.tap(find.text('Xếp hạng'));
      await tester.pumpAndSettle();
      if (const bool.fromEnvironment('ROOMS_MOCK_ENABLED', defaultValue: true)) {
        expect(find.text('Bảo · giả lập'), findsOneWidget);
        expect(find.text('1000'), findsOneWidget);
      } else {
        expect(find.text('Minh'), findsOneWidget);
        expect(find.text('1550'), findsOneWidget);
      }
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('PROTECTED DETAIL')),
        ),
      );
      await tester.pumpAndSettle();
      showModalBottomSheet<void>(
        context: tester.element(find.text('PROTECTED DETAIL')),
        builder: (_) => const Text('PROTECTED SHEET'),
      );
      await tester.pumpAndSettle();
      expect(find.text('PROTECTED SHEET'), findsOneWidget);
      await tester.runAsync(client.auth.signOut);
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      expect(find.text('PROTECTED SHEET'), findsNothing);
      expect(find.text('PROTECTED DETAIL'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Restored session skips login; missing profile does not start a login loop',
    (tester) async {
      final calls = <http.Request>[];
      final client = (await tester.runAsync(() async {
        final c = clientFor(calls, missingProfile: true);
        await c.auth.signInWithPassword(
          email: 'b@example.com',
          password: 'password123',
        );
        return c;
      }))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(SportXpApp(client: client));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ chưa khả dụng'), findsOneWidget);
      expect(find.text('Chào mừng trở lại.'), findsNothing);
      expect(client.auth.currentSession, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
