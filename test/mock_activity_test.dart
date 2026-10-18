import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/feed/data/mock_activity_repository.dart';
import 'package:sport_xp_4/features/feed/domain/activity.dart';
import 'package:sport_xp_4/features/feed/presentation/activity_editor_page.dart';
import 'package:sport_xp_4/features/feed/presentation/activity_feed_page.dart';
import 'package:sport_xp_4/features/rooms/data/mock_room_repository.dart';
import 'package:sport_xp_4/features/rooms/domain/managed_room.dart';

void main() {
  late MockRoomRepository rooms;
  late MockActivityRepository repo;
  setUp(() {
    rooms = MockRoomRepository(userId: 'me');
    repo = MockActivityRepository(rooms);
  });
  Future<ActivityView> draft(ActivityKind kind) async => (await repo.drafts())
      .firstWhere((p) => p.roomId == 'completed-demo' && p.kind == kind);
  Future<ActivityView> publish({
    ActivityKind kind = ActivityKind.personal,
    ActivityAudience audience = ActivityAudience.friends,
  }) async {
    final p = await draft(kind);
    await repo.execute(
      ActivityCommand(
        'publish',
        activityId: p.id,
        expectedVersion: p.version,
        caption: 'Một buổi cầu vui!',
        audience: audience,
      ),
    );
    return (await repo.get(p.id))!;
  }

  test('Drafts originate from completed logs, with separate personal and host posts', () async {
    expect(await repo.list(), isEmpty);
    expect(await repo.drafts(), hasLength(2));
    final personal = await draft(ActivityKind.personal),
        group = await draft(ActivityKind.hostSummary);
    expect(personal.id, isNot(group.id));
    expect(personal.totals.confirmed, 1);
    expect(personal.totals.pending, 1);
    expect(personal.totals.wins, 1);
    expect(personal.totals.losses, 0);
    expect(group.totals.wins, isNull);
    rooms.selectActor('linh');
    expect(await repo.drafts(), hasLength(1));
    rooms.selectActor('bao');
    expect(await repo.drafts(), isEmpty);
  });
  test('Friends see only published friends-audience posts, never drafts or only-me', () async {
    final p = await publish();
    final g = await publish(
      kind: ActivityKind.hostSummary,
      audience: ActivityAudience.onlyMe,
    );
    rooms.selectActor('linh');
    expect((await repo.list()).map((p) => p.id), [p.id]);
    expect(await repo.get(g.id), isNull);
    rooms.selectActor('minh');
    expect(await repo.list(), isEmpty);
    expect(await repo.get(p.id), isNull);
    rooms.selectActor('me');
    expect(await repo.list(mine: true), hasLength(2));
  });
  test('Late confirmation updates every post summary without touching captions or post versions', () async {
    final p = await publish(),
        g = await publish(kind: ActivityKind.hostSummary);
    rooms.selectActor('minh');
    await rooms.execute(
      RoomCommand(
        'match_confirm',
        roomId: 'completed-demo',
        payload: {'match_id': 'demo-pending', 'expected_version': 1},
      ),
    );
    rooms.selectActor('me');
    final updated = (await repo.get(p.id))!, group = (await repo.get(g.id))!;
    expect(updated.totals.confirmed, 2);
    expect(updated.totals.pending, 0);
    expect(updated.totals.losses, 1);
    expect(updated.resultsUpdated, true);
    expect(group.resultsUpdated, true);
    expect(updated.caption, p.caption);
    expect(updated.version, p.version);
  });
  test('Disputed and void matches never contribute to win/loss', () async {
    final p = await publish();
    rooms.selectActor('minh');
    await rooms.execute(
      RoomCommand(
        'match_dispute',
        roomId: 'completed-demo',
        payload: {
          'match_id': 'demo-pending',
          'expected_version': 1,
          'reason': 'Lý do riêng tư',
        },
      ),
    );
    rooms.selectActor('me');
    var view = (await repo.get(p.id))!;
    expect(view.totals.disputed, 1);
    expect(view.totals.wins, 1);
    expect(view.totals.losses, 0);
    await rooms.execute(
      RoomCommand(
        'match_void',
        roomId: 'completed-demo',
        payload: {
          'match_id': 'demo-pending',
          'expected_version': 2,
          'reason': 'Hủy bản ghi sai',
        },
      ),
    );
    view = (await repo.get(p.id))!;
    expect(view.totals.total, 1);
    expect(view.totals.voided, 1);
    expect(view.caption, isNot(contains('Lý do riêng tư')));
  });
  test('Unfriend and block revoke list, detail and reaction access without changing actual Auth', () async {
    final p = await publish();
    rooms.selectActor('linh');
    rooms.setMockFriend('me', false);
    expect(await repo.get(p.id), isNull);
    expect(await repo.list(), isEmpty);
    await expectLater(
      repo.execute(ActivityCommand('react', activityId: p.id, liked: true)),
      throwsException,
    );
    rooms.setMockFriend('me', true);
    expect(await repo.get(p.id), isNotNull);
    rooms.setMockBlock('me', true);
    expect(await repo.get(p.id), isNull);
    rooms.setMockBlock('me', false);
    expect(
      await repo.get(p.id),
      isNull,
    ); // unblocking does not restore friendship
  });
  test(
    'Reaction sets are idempotent and do not change content version',
    () async {
      final p = await publish();
      rooms.selectActor('linh');
      final c = ActivityCommand('react', activityId: p.id, liked: true);
      await repo.execute(c);
      await repo.execute(c);
      expect((await repo.get(p.id))!.likeCount, 1);
      expect((await repo.get(p.id))!.version, p.version);
      await repo.execute(
        ActivityCommand('react', activityId: p.id, liked: false),
      );
      expect((await repo.get(p.id))!.likeCount, 0);
    },
  );
  test('Publish retries cannot duplicate; content updates require ownership and current version', () async {
    final d = await draft(ActivityKind.personal);
    final c = ActivityCommand(
      'publish',
      activityId: d.id,
      expectedVersion: d.version,
      caption: 'Caption',
      audience: ActivityAudience.friends,
    );
    await repo.execute(c);
    await repo.execute(c);
    expect(await repo.list(), hasLength(1));
    await expectLater(
      repo.execute(
        ActivityCommand(
          'publish',
          activityId: d.id,
          expectedVersion: d.version,
          caption: 'Other',
          audience: ActivityAudience.friends,
          requestId: c.requestId,
        ),
      ),
      throwsException,
    );
    rooms.selectActor('linh');
    await expectLater(
      repo.execute(
        ActivityCommand(
          'save',
          activityId: d.id,
          expectedVersion: 2,
          caption: 'Sửa của bạn',
          audience: ActivityAudience.onlyMe,
        ),
      ),
      throwsException,
    );
    rooms.selectActor('me');
    await expectLater(
      repo.execute(
        ActivityCommand(
          'save',
          activityId: d.id,
          expectedVersion: 1,
          caption: 'Stale',
          audience: ActivityAudience.onlyMe,
        ),
      ),
      throwsException,
    );
    await repo.execute(
      ActivityCommand(
        'save',
        activityId: d.id,
        expectedVersion: 2,
        caption: 'Mới',
        audience: ActivityAudience.onlyMe,
      ),
    );
    rooms.selectActor('linh');
    expect(await repo.get(d.id), isNull);
  });
  test('Delete tombstone hides the post permanently but preserves log and other posts', () async {
    final p = await publish(),
        g = await publish(kind: ActivityKind.hostSummary);
    final c = ActivityCommand(
      'delete',
      activityId: p.id,
      expectedVersion: p.version,
    );
    await repo.execute(c);
    await repo.execute(c);
    expect(await repo.get(p.id), isNull);
    expect((await repo.drafts()).where((d) => d.id == p.id), isEmpty);
    expect(await repo.get(g.id), isNotNull);
    expect((await rooms.session('completed-demo'))['matches'], hasLength(2));
  });
  test('Reset clears all posts, receipts and reactions and regenerates clean drafts', () async {
    await publish();
    rooms.reset();
    expect(await repo.list(), isEmpty);
    expect(await repo.drafts(), hasLength(2));
  });
  test('A fresh completed session is available as drafts and includes only own matches', () async {
    await expectLater(
      rooms.execute(
        RoomCommand(
          'match_create',
          roomId: 'playing-demo',
          payload: {
            'team_a': ['linh'],
            'team_b': ['minh'],
            'score': '21-19',
            'winner': 'A',
          },
        ),
      ),
      throwsException,
    );
    await rooms.execute(RoomCommand('finish', roomId: 'playing-demo'));
    expect(
      (await repo.drafts()).where((d) => d.roomId == 'playing-demo'),
      hasLength(2),
    );
  });
  test(
    'Private log metadata is redacted for friends outside the session',
    () async {
      final privateRepo = MockActivityRepository(_PrivateSource(rooms));
      final d = (await privateRepo.drafts()).firstWhere(
        (p) => p.kind == ActivityKind.personal,
      );
      await privateRepo.execute(
        ActivityCommand(
          'publish',
          activityId: d.id,
          expectedVersion: d.version,
          caption: 'Buổi vui',
          audience: ActivityAudience.friends,
        ),
      );
      rooms.selectActor('bao');
      rooms.setMockFriend('me', true);
      final view = (await privateRepo.get(d.id))!;
      expect(view.title, 'Buổi chơi riêng tư');
      expect(view.courtName, 'Địa điểm riêng tư');
      expect(view.canOpenLog, false);
      rooms.selectActor('me');
      expect((await privateRepo.get(d.id))!.courtName, contains('Đào Duy Anh'));
    },
  );
  testWidgets(
    'Preview is required before publishing; UI publishes caption and returns to feed',
    (tester) async {
      final d = await draft(ActivityKind.personal);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActivityEditorPage(repository: repo, post: d),
                  ),
                ),
                child: const Text('Soạn bài'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Soạn bài'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Đăng bài'))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Caption UI');
      await tester.scrollUntilVisible(
        find.text('Xem trước'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Đăng bài'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng bài'));
      await tester.pumpAndSettle();
      expect((await repo.get(d.id))!.caption, 'Caption UI');
      expect((await repo.get(d.id))!.isDraft, false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Empty feed offers own drafts and room discovery instead of public strangers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: ActivityFeedPage(
              repository: repo,
              rooms: rooms,
              refreshToken: 0,
              onFindRooms: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nháp từ log (2)'), findsOneWidget);
      expect(
        find.textContaining('Chưa có hoạt động được chia sẻ'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _PrivateSource implements ActivityLogSource {
  _PrivateSource(this.rooms);
  final MockRoomRepository rooms;
  @override
  String get actorId => rooms.actorId;
  @override
  int get generation => rooms.generation;
  @override
  Map<String, String> get actorNames => rooms.actorNames;
  @override
  bool areFriends(String a, String b) => rooms.areFriends(a, b);
  @override
  bool isBlocked(String a, String b) => rooms.isBlocked(a, b);
  @override
  List<ActivityLog> activityLogs() => [
    for (final log in rooms.activityLogs())
      ActivityLog(
        roomId: log.roomId,
        hostId: log.hostId,
        title: log.title,
        courtName: log.courtName,
        isPrivate: true,
        endedAt: log.endedAt,
        players: log.players,
        matches: log.matches,
      ),
  ];
}
