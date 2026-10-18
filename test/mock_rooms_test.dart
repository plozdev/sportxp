import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/domain/managed_room.dart';
import 'package:sport_xp_4/features/rooms/domain/room_search.dart';
import 'package:sport_xp_4/features/rooms/presentation/room_detail_page.dart';
import 'package:sport_xp_4/features/rooms/presentation/room_session_page.dart';

void main() {
  late MockRoomRepository repo;
  setUp(() => repo = MockRoomRepository(userId: 'me'));
  Future<String> send(
    String action,
    String id, [
    Map<String, dynamic> p = const {},
  ]) => repo.execute(RoomCommand(action, roomId: id, payload: p));
  Future<Map<String, dynamic>> match() async =>
      ((await repo.session('playing-demo'))['matches'] as List).last
          as Map<String, dynamic>;
  Map<String, dynamic> result({String score = '21-19', String winner = 'A'}) =>
      {
        'team_a': ['me', 'linh'],
        'team_b': ['minh', 'an'],
        'score': score,
        'winner': winner,
      };
  test('Public discovery excludes private; friends-only private visibility is simulated', () async {
    expect(
      (await repo.list('discover')).map((r) => r.id),
      isNot(contains('private-demo')),
    );
    expect(
      (await repo.list('connections')).map((r) => r.id),
      contains('private-demo'),
    );
    repo.selectActor('an');
    final terms = (await repo.get('host-demo'))!.editableTerms;
    repo.selectActor('me');
    await send('edit', 'host-demo', {...terms, 'visibility': 'PRIVATE'});
    repo.selectActor('bao');
    expect(await repo.get('host-demo'), isNull);
    repo.selectActor('linh');
    expect(await repo.get('host-demo'), isNotNull);
  });
  test(
    'Create is idempotent; altered retry rejected; organizer consumes no slot',
    () async {
      final p = (await repo.get('host-demo'))!.editableTerms;
      final command = RoomCommand(
        'create',
        payload: {...p, 'host_plays': false, 'draft': true},
      );
      final id = await repo.execute(command);
      expect(await repo.execute(command), id);
      final room = (await repo.get(id))!;
      expect(room.reserved, 0);
      expect(room.hostPlays, false);
      await expectLater(
        repo.execute(
          RoomCommand(
            'create',
            requestId: command.requestId,
            payload: {...command.payload, 'title': 'changed'},
          ),
        ),
        throwsException,
      );
    },
  );
  test('Join, waitlist and cancellation promote exactly one eligible waiting player', () async {
    await send('waitlist', 'full-demo', {'expected_revision': 1});
    repo.selectActor('bao');
    await send('leave', 'full-demo');
    repo.selectActor('me');
    final room = (await repo.get('full-demo'))!;
    expect(room.myStatus, 'REGISTERED');
    expect(room.reserved, 4);
    expect(
      (await repo.notices()).where((n) => n['kind'] == 'PROMOTED'),
      isNotEmpty,
    );
  });
  test('Edits keep seats but require consent to current revision', () async {
    repo.selectActor('linh');
    final p = (await repo.get('open-demo'))!.editableTerms;
    await send('edit', 'open-demo', {...p, 'fee': 50000});
    repo.selectActor('minh');
    expect((await repo.get('open-demo'))!.myStatus, 'RECONFIRM');
    await expectLater(
      send('reconfirm', 'open-demo', {'expected_revision': 1}),
      throwsException,
    );
    await send('reconfirm', 'open-demo', {'expected_revision': 2});
    expect((await repo.get('open-demo'))!.myStatus, 'REGISTERED');
  });
  test(
    'Host calendar overlap is rejected and rejected edit leaves room intact',
    () async {
      final terms = (await repo.get('host-demo'))!.editableTerms;
      await expectLater(
        repo.execute(RoomCommand('create', payload: terms)),
        throwsException,
      );
      await expectLater(
        send('edit', 'host-demo', {...terms, 'capacity': 2}),
        throwsException,
      );
      expect((await repo.get('host-demo'))!.capacity, 4);
      expect((await repo.get('host-demo'))!.revision, 1);
    },
  );
  test('Only opposing participant confirms, once; snapshot read cannot mutate store', () async {
    final c = RoomCommand(
      'match_create',
      roomId: 'playing-demo',
      payload: result(),
    );
    await repo.execute(c);
    await repo.execute(c);
    expect((await repo.session('playing-demo'))['matches'], hasLength(1));
    final m = await match();
    await expectLater(
      send('match_confirm', 'playing-demo', {
        'match_id': m['id'],
        'expected_version': 1,
      }),
      throwsException,
    );
    repo.selectActor('minh');
    final confirmation = RoomCommand(
      'match_confirm',
      roomId: 'playing-demo',
      payload: {'match_id': m['id'], 'expected_version': 1},
    );
    await repo.execute(confirmation);
    await repo.execute(confirmation);
    expect((await match())['status'], 'CONFIRMED');
    m['status'] = 'VOID';
    expect((await match())['status'], 'CONFIRMED');
    await expectLater(
      send('match_confirm', 'playing-demo', {
        'match_id': m['id'],
        'expected_version': 1,
      }),
      throwsException,
    );
  });
  test('Dispute, author correction and re-confirm reset version; scores agree with winner', () async {
    await expectLater(
      send('match_create', 'playing-demo', result(winner: 'B')),
      throwsException,
    );
    await expectLater(
      send('match_create', 'playing-demo', result(score: '21-21')),
      throwsException,
    );
    await send('match_create', 'playing-demo', result());
    var m = await match();
    repo.selectActor('an');
    await send('match_dispute', 'playing-demo', {
      'match_id': m['id'],
      'expected_version': 1,
      'reason': 'Sai tỉ số',
    });
    repo.selectActor('me');
    await expectLater(
      send('match_edit', 'playing-demo', {
        ...result(),
        'match_id': m['id'],
        'expected_version': 1,
      }),
      throwsException,
    );
    await send('match_edit', 'playing-demo', {
      ...result(score: '21-18'),
      'match_id': m['id'],
      'expected_version': 2,
    });
    m = await match();
    expect(m['status'], 'PENDING');
    expect(m['version'], 3);
    expect(m['confirmed_by'], isEmpty);
  });
  test('Duplicate players and a host who is not a participant cannot report a match', () async {
    await expectLater(
      send('match_create', 'playing-demo', {
        'team_a': ['me', 'me'],
        'team_b': ['minh', 'an'],
        'score': '21-19',
        'winner': 'A',
      }),
      throwsException,
    );
    await expectLater(
      send('match_create', 'playing-demo', {
        'team_a': ['linh'],
        'team_b': ['minh'],
        'score': '21-19',
        'winner': 'A',
      }),
      throwsException,
    );
  });
  test(
    'Host attendance, player objection and resolution keep versioned record',
    () async {
      await expectLater(
        send('attendance_mark', 'playing-demo', {
          'player_id': 'me',
          'expected_version': 0,
          'outcome': 'PRESENT',
          'reason': 'Tự đánh giá',
        }),
        throwsException,
      );
      await send('attendance_mark', 'playing-demo', {
        'player_id': 'minh',
        'expected_version': 0,
        'outcome': 'ABSENT',
        'reason': 'Chưa thấy tại sân',
      });
      repo.selectActor('an');
      await expectLater(
        send('attendance_dispute', 'playing-demo', {
          'player_id': 'minh',
          'expected_version': 1,
          'reason': 'Có đến',
        }),
        throwsException,
      );
      repo.selectActor('minh');
      await send('attendance_dispute', 'playing-demo', {
        'player_id': 'minh',
        'expected_version': 1,
        'reason': 'Đã có mặt',
      });
      repo.selectActor('me');
      await send('attendance_resolve', 'playing-demo', {
        'player_id': 'minh',
        'expected_version': 2,
        'outcome': 'PRESENT',
        'reason': 'Đã kiểm tra lại',
      });
      final s = await repo.session('playing-demo');
      expect(s['attendance']['minh']['status'], 'RESOLVED');
      expect(s['attendance']['minh']['version'], 3);
      expect(s['audit'], hasLength(3));
    },
  );
  test('Finish does not confirm pending matches; confirmation still possible afterwards', () async {
    await send('match_create', 'playing-demo', result());
    await send('finish', 'playing-demo');
    final m = await match();
    expect(m['status'], 'PENDING');
    await expectLater(
      send('match_create', 'playing-demo', result()),
      throwsException,
    );
    repo.selectActor('minh');
    await send('match_confirm', 'playing-demo', {
      'match_id': m['id'],
      'expected_version': 1,
    });
    expect((await match())['status'], 'CONFIRMED');
  });
  test('Search filters before pagination', () async {
    final open = (await repo.get('open-demo'))!;
    expect(
      await repo.list(
        'discover',
        search: const RoomSearch(
          area: 'Phú Nhuận',
          maxDistanceKm: 3,
          availableOnly: true,
          skill: 750,
          maxFee: 40000,
        ),
      ),
      hasLength(1),
    );
    expect(
      await repo.list('discover', search: const RoomSearch(maxFee: 1000)),
      isEmpty,
    );
    expect(
      await repo.list('discover', search: const RoomSearch(skill: 3000)),
      isEmpty,
    );
    expect(
      await repo.list('discover', search: RoomSearch(date: open.startsAt)),
      hasLength(1),
    );
    expect(
      await repo.list(
        'discover',
        offset: 1,
        search: const RoomSearch(
          area: 'Phú Nhuận',
          maxDistanceKm: 3,
          availableOnly: true,
        ),
      ),
      isEmpty,
    );
  });
  test('Draft remains host-only and cancellation requires reason', () async {
    final terms = (await repo.get('host-demo'))!.editableTerms;
    final id = await repo.execute(
      RoomCommand('create', payload: {...terms, 'draft': true}),
    );
    repo.selectActor('linh');
    expect(await repo.get(id), isNull);
    await expectLater(send('publish', id), throwsException);
    repo.selectActor('me');
    await expectLater(send('publish', id), throwsException);
    await expectLater(send('cancel', id), throwsException);
    await send('cancel', id, {'reason': 'Đổi lịch'});
    expect((await repo.get(id))!.status, 'CANCELLED');
  });
  test('Immutable command snapshots nested teams', () {
    final ids = ['me'];
    final command = RoomCommand('match_create', payload: {'team_a': ids});
    ids.add('linh');
    expect(command.payload['team_a'], ['me']);
    expect(
      () => (command.payload['team_a'] as List).add('minh'),
      throwsUnsupportedError,
    );
  });
  test(
    'Blocking revokes waiting consent; refriending does not restore it',
    () async {
      await send('waitlist', 'full-demo', {'expected_revision': 1});
      repo.setMockBlock('minh', true);
      expect((await repo.get('full-demo'))!.myStatus, 'CANCELLED');
      repo.setMockBlock('minh', false);
      repo.setMockFriend('minh', true);
      repo.selectActor('bao');
      await send('leave', 'full-demo');
      repo.selectActor('me');
      expect((await repo.get('full-demo'))!.myStatus, 'CANCELLED');
    },
  );
  testWidgets(
    'Room opens session UI; actions and role selector are reachable',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RoomDetailPage(repository: repo, roomId: 'playing-demo'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Trận đấu / Điểm danh'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -160));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trận đấu / Điểm danh'));
      await tester.pumpAndSettle();
      expect(find.byType(RoomSessionPage), findsOneWidget);
      expect(find.text('+ Ghi trận đơn / đôi'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('+ Ghi trận đơn / đôi'));
      await tester.pumpAndSettle();
      expect(find.text('Gửi kết quả'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
