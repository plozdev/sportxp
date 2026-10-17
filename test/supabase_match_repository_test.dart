import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/features/feed/domain/match_draft.dart';
import 'package:sport_xp_4/features/matchmaking/data/supabase_match_repository.dart';
import 'package:sport_xp_4/features/matchmaking/domain/create_room_draft.dart';

http.Response response(
  http.Request request,
  Object? data, {
  int status = 200,
}) => http.Response(
  data == null ? '' : jsonEncode(data),
  status,
  request: request,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> room({
  List<String>? players,
  String status = 'OPEN',
  int capacity = 4,
}) => {
  'id': 'room-1',
  'host_id': 'host',
  'play_time': DateTime.now()
      .add(const Duration(days: 1))
      .toUtc()
      .toIso8601String(),
  'max_slots': capacity,
  'current_players': players ?? ['host'],
  'status': status,
  'courts': {'name': 'Sân A', 'distance_km': 1.8},
};

Future<SupabaseClient> makeClient(
  Future<http.Response> Function(http.Request) handler, {
  bool signedIn = true,
}) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-public',
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return response(request, {
          'access_token': 'test-access',
          'refresh_token': 'test-refresh',
          'expires_in': 3600,
          'token_type': 'bearer',
          'user': {
            'id': 'me',
            'aud': 'authenticated',
            'email': 'me@example.com',
            'created_at': '2026-10-18T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          },
        });
      }
      return handler(request);
    }),
  );
  addTearDown(client.dispose);
  if (signedIn) {
    await client.auth.signInWithPassword(
      email: 'me@example.com',
      password: 'password',
    );
  }
  return client;
}

void main() {
  test(
    'Reads exact feed fields, descending order, court join and open status',
    () async {
      final client = await makeClient((r) async {
        switch (r.url.path) {
          case '/rest/v1/match_results':
            expect(r.url.queryParameters['order'], 'created_at.desc.nullslast');
            return response(r, [
              {
                'id': 'result-1',
                'court_name': 'Sân A',
                'team_a_names': 'An',
                'team_b_names': 'Bình',
                'score_text': '19-21',
                'winner_team': 'B',
                'elo_change': -18,
                'created_at': '2026-10-18T00:00:00Z',
              },
            ]);
          case '/rest/v1/match_rooms':
            expect(r.url.queryParameters['status'], 'eq.OPEN');
            expect(
              r.url.queryParameters['select'],
              contains('courts(name,distance_km)'),
            );
            return response(r, [room(players: [])]);
          case '/rest/v1/courts':
            return response(r, [
              {'id': 'court-1', 'name': 'Sân A', 'distance_km': 1.8},
            ]);
        }
        fail('Unexpected endpoint');
      }, signedIn: false);
      final repo = SupabaseMatchRepository(client);
      final result = (await repo.feed()).single;
      expect(result.isWin, false);
      expect(result.eloChange, -18);
      expect(result.teamA, 'An');
      expect(result.score, '19-21');
      expect((await repo.openRooms()).single.availableSlots, 4);
      expect((await repo.courts()).single.distanceKm, 1.8);
    },
  );

  test(
    'Creates room with authenticated host and UTC; RPC uses exact parameters once',
    () async {
      final requests = <http.Request>[];
      final client = await makeClient((r) async {
        requests.add(r);
        return response(r, null, status: 204);
      });
      final repo = SupabaseMatchRepository(client);
      final time = DateTime.now().add(const Duration(days: 1));
      await repo.createRoom(
        CreateRoomDraft(courtId: 'court-1', startsAt: time, maxSlots: 6),
      );
      final body = jsonDecode(requests.single.body);
      expect(body['host_id'], 'me');
      expect(body['current_players'], ['me']);
      expect(body['max_slots'], 6);
      expect(body['status'], 'OPEN');
      expect(body['play_time'], time.toUtc().toIso8601String());
      await repo.recordMatch(
        const MatchDraft(
          courtName: 'Sân A',
          teamA: 'An',
          teamB: 'Bình',
          score: '21-19',
          isWin: true,
        ),
      );
      expect(
        requests.last.url.path,
        '/rest/v1/rpc/record_match_and_update_elo',
      );
      expect(jsonDecode(requests.last.body), {
        'p_user_id': 'me',
        'p_court_name': 'Sân A',
        'p_team_a': 'An',
        'p_team_b': 'Bình',
        'p_score': '21-19',
        'p_is_win': true,
      });
      expect(requests.length, 2);
    },
  );

  test(
    'Concurrent join retries compare-and-swap and preserves other players',
    () async {
      var reads = 0, updates = 0;
      final client = await makeClient((r) async {
        if (r.method == 'GET') {
          reads++;
          return response(
            r,
            room(players: reads == 1 ? ['host'] : ['host', 'other']),
          );
        }
        updates++;
        final body = jsonDecode(r.body);
        expect(r.url.queryParameters['status'], 'eq.OPEN');
        expect(r.url.queryParameters['max_slots'], 'eq.4');
        if (updates == 1) {
          expect(r.url.queryParameters['current_players'], 'eq.{"host"}');
          return response(r, []);
        }
        expect(r.url.queryParameters['current_players'], 'eq.{"host","other"}');
        expect(body['current_players'], ['host', 'other', 'me']);
        expect(body['status'], 'OPEN');
        return response(r, [
          {'id': 'room-1'},
        ]);
      });
      await SupabaseMatchRepository(client).joinRoom('room-1');
      expect(reads, 2);
      expect(updates, 2);
    },
  );

  test('Last slot sets FULL; existing member never appends twice', () async {
    var updates = 0;
    final client = await makeClient((r) async {
      if (r.method == 'GET') {
        return response(
          r,
          room(
            players: updates == 0
                ? ['host', 'a', 'b']
                : ['host', 'a', 'b', 'me'],
            status: updates == 0 ? 'OPEN' : 'FULL',
          ),
        );
      }
      updates++;
      expect(jsonDecode(r.body)['status'], 'FULL');
      return response(r, [
        {'id': 'room-1'},
      ]);
    });
    final repo = SupabaseMatchRepository(client);
    await repo.joinRoom('room-1');
    await repo.joinRoom('room-1');
    expect(updates, 1);
  });

  test(
    'Full room blocks joins and anonymous mutations fail before HTTP',
    () async {
      var writes = 0;
      final client = await makeClient((r) async {
        if (r.method != 'GET') writes++;
        return response(
          r,
          room(players: ['host', 'a', 'b', 'c'], status: 'FULL'),
        );
      });
      await expectLater(
        SupabaseMatchRepository(client).joinRoom('room-1'),
        throwsStateError,
      );
      expect(writes, 0);
      final guest = await makeClient(
        (r) async => fail('Guest must not send mutation'),
        signedIn: false,
      );
      await expectLater(
        SupabaseMatchRepository(guest).recordMatch(
          const MatchDraft(
            courtName: 'Sân A',
            teamA: 'A',
            teamB: 'B',
            score: '21-19',
            isWin: true,
          ),
        ),
        throwsA(isA<AuthException>()),
      );
    },
  );
}

