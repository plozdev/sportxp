import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/auth/presentation/auth_sheet.dart';

void main() {
  testWidgets('Signup without session asks for email confirmation', (
    tester,
  ) async {
    Map<String, dynamic>? payload;
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.supabase.co',
        'test-public',
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/auth/v1/signup');
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'aud': 'authenticated',
              'email': 'test@example.com',
              'created_at': '2026-10-18T00:00:00Z',
              'app_metadata': {},
              'user_metadata': {},
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    ))!;
    addTearDown(() async => tester.runAsync(client.dispose));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: AuthSheet(client: client)),
      ),
    );
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Minh');
    await tester.enterText(fields.at(1), 'test@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.ensureVisible(find.text('ĐĂNG KÝ'));
    await tester.tap(find.text('ĐĂNG KÝ'));
    await tester.pumpAndSettle();
    expect(client.auth.currentSession, isNull);
    expect(
      find.text('Kiểm tra email để xác nhận tài khoản, sau đó đăng nhập.'),
      findsOneWidget,
    );
    expect(payload?['data']['display_name'], 'Minh');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Bad credentials remain in form with an actionable auth error', (
    tester,
  ) async {
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.supabase.co',
        'test-public',
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['grant_type'], 'password');
          return http.Response(
            jsonEncode({
              'msg': 'Invalid login credentials',
              'code': 'invalid_credentials',
            }),
            400,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    ))!;
    addTearDown(() async => tester.runAsync(client.dispose));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: AuthSheet(client: client)),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'bad-password');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid login credentials'), findsOneWidget);
    expect(client.auth.currentSession, isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
