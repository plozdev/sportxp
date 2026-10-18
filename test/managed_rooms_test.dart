import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/rooms/domain/managed_room.dart';
import 'package:sport_xp_4/features/rooms/data/managed_room_repository.dart';
import 'package:sport_xp_4/features/rooms/presentation/room_editor_page.dart';
import 'package:sport_xp_4/features/rooms/presentation/room_detail_page.dart';
import 'package:sport_xp_4/app/sport_xp_app.dart';

const roomId = '00000000-0000-4000-8000-000000000001';
const userId = '00000000-0000-4000-8000-000000000002';
const courtId = '00000000-0000-4000-8000-000000000003';
Map<String, dynamic> roomJson({String myStatus = 'RECONFIRM'}) => {
  'id': roomId,
  'court_id': courtId,
  'title': 'Buổi chơi A',
  'court_name': 'Sân A',
  'court_address': 'Địa chỉ sân',
  'starts_at': DateTime.now()
      .add(const Duration(days: 2))
      .toUtc()
      .toIso8601String(),
  'ends_at': DateTime.now()
      .add(const Duration(days: 2, hours: 2))
      .toUtc()
      .toIso8601String(),
  'cancel_by': DateTime.now()
      .add(const Duration(days: 1, hours: 23))
      .toUtc()
      .toIso8601String(),
  'capacity': 4,
  'reserved': 2,
  'min_elo': 0,
  'max_elo': 2000,
  'fee': 40000,
  'revision': 2,
  'visibility': 'PRIVATE',
  'status': 'OPEN',
  'host_plays': false,
  'is_host': false,
  'host_name': 'Host',
  'my_status': myStatus,
  'notes': '',
  'court_label': '',
  'members': [],
};
Future<SupabaseClient> signedClient(
  Future<http.Response> Function(http.Request) handler,
) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'public-key',
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/token')) {
        return http.Response(
          jsonEncode({
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
          }),
          200,
          request: r,
          headers: {'content-type': 'application/json'},
        );
      }
      return handler(r);
    }),
  );
  await client.auth.signInWithPassword(
    email: 'b@example.com',
    password: 'password123',
  );
  return client;
}

http.Response response(http.Request r, Object? value, {int status = 200}) =>
    http.Response(
      jsonEncode(value),
      status,
      request: r,
      headers: {'content-type': 'application/json'},
    );

void main() {
  testWidgets(
    'Enabled 2A routes matchmaking and create to the managed room flow',
    (tester) async {
      final paths = <String>[];
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          final name = r.url.path.split('/').last;
          paths.add(name);
          if (name == 'get_onboarding_state') {
            return response(r, {
              'onboarding_step': 5,
              'answers': [0, 0, 0, 0, 0],
              'display_name': 'B',
              'elo_rating': 750,
              'tier_name': 'TB',
            });
          }
          if (name == 'profiles') {
            return response(
              r,
              r.url.queryParameters.containsKey('id')
                  ? {
                      'id': userId,
                      'display_name': 'B',
                      'elo_rating': 750,
                      'tier_name': 'TB',
                      'trust_score': 100,
                      'win_streak': 0,
                      'onboarding_step': 5,
                    }
                  : [],
            );
          }
          if (name == 'list_rooms_v2') return response(r, [roomJson()]);
          if (name == 'room_notices_v2') return response(r, []);
          if (name == 'courts') {
            return response(r, [
              {'id': courtId, 'name': 'Sân A'},
            ]);
          }
          return response(r, roomJson());
        }),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(SportXpApp(client: client, showSplash: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kèo đấu'));
      await tester.pumpAndSettle();
      expect(find.text('Buổi của tôi'), findsOneWidget);
      expect(paths, contains('list_rooms_v2'));
      await tester.tap(find.text('TẠO KÈO MỚI'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo buổi chơi'), findsOneWidget);
      expect(paths, contains('courts'));
      expect(paths, isNot(contains('match_rooms')));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !const bool.fromEnvironment('ROOMS_V2_ENABLED'),
  );
  test('Command IDs are UUID v4; payloads immutable and organizer does not imply a playing slot', () {
    final ids = List.generate(100, (_) => newRoomRequestId());
    expect(ids.toSet().length, 100);
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
    final command = RoomCommand('join', roomId: roomId);
    expect(() => command.payload['host_id'] = userId, throwsUnsupportedError);
    final room = ManagedRoom.fromJson(roomJson());
    expect(room.hostPlays, isFalse);
    expect(room.reserved, 2);
  });
  test('Repository retries the same command ID without client-written memberships or host IDs', () async {
    final requests = <Map<String, dynamic>>[];
    final client = await signedClient((r) async {
      requests.add(jsonDecode(r.body) as Map<String, dynamic>);
      return response(r, roomId);
    });
    addTearDown(client.dispose);
    final repo = ManagedRoomRepository(client),
        command = RoomCommand('join', roomId: roomId);
    await repo.execute(command);
    await repo.execute(command);
    expect(requests[0], requests[1]);
    expect(requests[0]['p_request_id'], command.requestId);
    expect(requests[0].containsKey('current_players'), isFalse);
    expect(requests[0].containsKey('host_id'), isFalse);
  });
  testWidgets(
    'Create retries after uncertain response reuse command, preserving server-managed slots',
    (tester) async {
      final commands = <Map<String, dynamic>>[];
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          if (r.url.path.endsWith('/courts')) {
            return response(r, [
              {'id': courtId, 'name': 'Sân A'},
            ]);
          }
          commands.add(jsonDecode(r.body) as Map<String, dynamic>);
          return commands.length == 1
              ? response(r, {
                  'message': 'uncertain commit',
                  'code': 'P0001',
                }, status: 400)
              : response(r, roomId);
        }),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomEditorPage(
                      repository: ManagedRoomRepository(client),
                    ),
                  ),
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sân A').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(SwitchListTile, 'Host cũng chơi'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Host cũng chơi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();
      expect(commands.length, 1);
      expect(commands[0]['p_payload']['host_plays'], false);
      expect(commands[0]['p_payload']['ends_at'], isNotNull);
      expect(commands[0]['p_payload']['cancel_by'], isNotNull);
      await tester.ensureVisible(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LƯU BUỔI CHƠI'));
      await tester.pumpAndSettle();
      expect(commands.length, 2);
      expect(commands[1], commands[0]);
      expect(find.text('Mở'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Reconfirmation sends the displayed revision and refreshes only after committing',
    (tester) async {
      String status = 'RECONFIRM';
      Map<String, dynamic>? sent;
      final client = (await tester.runAsync(
        () => signedClient((r) async {
          if (r.url.path.endsWith('get_room_v2')) {
            return response(r, roomJson(myStatus: status));
          }
          sent = jsonDecode(r.body) as Map<String, dynamic>;
          status = 'REGISTERED';
          return response(r, roomId);
        }),
      ))!;
      addTearDown(() => tester.runAsync(client.dispose));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RoomDetailPage(
            repository: ManagedRoomRepository(client),
            roomId: roomId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Đồng ý điều kiện mới'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đồng ý điều kiện mới'));
      await tester.pumpAndSettle();
      expect(sent?['p_action'], 'reconfirm');
      expect(sent?['p_payload'], {'expected_revision': 2});
      expect(find.text('Đồng ý điều kiện mới'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
