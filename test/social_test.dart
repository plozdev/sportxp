import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/app/sport_xp_app.dart';
import 'package:sport_xp_4/features/social/data/social_repository.dart';
import 'package:sport_xp_4/features/social/domain/profile_link.dart';
import 'package:sport_xp_4/features/onboarding/domain/onboarding_quiz.dart';

const publicId = '00000000-0000-4000-8000-000000000001';
void main() {
  test('Profile links accept only profile routes and trusted schemes', () {
    expect(ProfileLink.parse(ProfileLink.build(publicId)), publicId);
    expect(ProfileLink.parse('/p/$publicId'), publicId);
    for (final bad in [
      'https://evil.test/p/$publicId',
      'javascript:alert(1)',
      'sportxp://room/$publicId',
      '/p/not-a-uuid',
      '/p/$publicId/extra',
      '//evil.test/p/$publicId',
    ]) {
      expect(ProfileLink.parse(bad), isNull, reason: bad);
    }
  });
  test('Social repository uses RPC actions and explicit pagination', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        requests.add(r);
        return http.Response(
          r.url.path.endsWith('list_social_connections') ? '[]' : 'null',
          200,
          request: r,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repo = SocialRepository(client);
    await repo.action(publicId, 'request');
    await repo.connections('incoming', offset: 50);
    expect(requests[0].url.path, '/rest/v1/rpc/social_action');
    expect(jsonDecode(requests[0].body), {
      'p_public_id': publicId,
      'p_action': 'request',
    });
    expect(jsonDecode(requests[1].body), {
      'p_kind': 'incoming',
      'p_offset': 50,
    });
  });

  testWidgets(
    'QR destination survives required login and onboarding; no automatic friend request',
    (tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = '/p/$publicId';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final calls = <String>[];
      var relation = 'none';
      var step = 4;
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'public-test',
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
          httpClient: MockClient((r) async {
            final name = r.url.path.split('/').last;
            calls.add(name);
            Object? body;
            if (name == 'token') {
              body = {
                'access_token': 'test-token',
                'token_type': 'bearer',
                'expires_in': 3600,
                'refresh_token': 'refresh',
                'user': {
                  'id': '00000000-0000-4000-8000-000000000002',
                  'aud': 'authenticated',
                  'email': 'b@example.com',
                  'created_at': '2026-10-18T00:00:00Z',
                  'app_metadata': {},
                  'user_metadata': {},
                },
              };
            } else if (name == 'get_onboarding_state' ||
                name == 'save_onboarding_answer') {
              if (name == 'save_onboarding_answer') step = 5;
              body = {
                'onboarding_step': step,
                'answers': List.filled(step, 0),
                'display_name': 'B',
                'elo_rating': step == 5 ? 750 : null,
                'tier_name': step == 5 ? 'TB' : null,
              };
            } else if (name == 'social_action') {
              relation = 'outgoing';
              body = null;
            } else if (name == 'get_social_profile') {
              expect(jsonDecode(r.body)['p_public_id'], publicId);
              body = {
                'public_id': publicId,
                'display_name': 'Minh',
                'elo_rating': 750,
                'tier_name': 'TB',
                'relationship': relation,
              };
            } else if (name == 'profiles') {
              body = r.url.queryParameters.containsKey('id')
                  ? {
                      'id': '00000000-0000-4000-8000-000000000002',
                      'display_name': 'B',
                      'elo_rating': 750,
                      'tier_name': 'TB',
                      'trust_score': 100,
                      'win_streak': 0,
                      'onboarding_step': 5,
                    }
                  : [];
            } else {
              body = null;
            }
            return http.Response(
              jsonEncode(body),
              200,
              request: r,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(SportXpApp(client: client));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      expect(find.text('Minh'), findsNothing);
      expect(calls, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(0), 'b@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'ĐĂNG NHẬP'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c == 'get_social_profile'), isEmpty);
      final choice = find.text(OnboardingQuiz.questions[4].choices[0].label);
      await tester.scrollUntilVisible(
        choice,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(tester.element(choice), alignment: .2);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('BẮT ĐẦU LÊN SÂN'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('BẮT ĐẦU LÊN SÂN'));
      await tester.pumpAndSettle();
      expect(find.text('Minh'), findsOneWidget);
      expect(calls.where((c) => c == 'social_action'), isEmpty);
      await tester.tap(find.text('KẾT BẠN'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c == 'social_action').length, 1);
      expect(find.text('HỦY LỜI MỜI'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
