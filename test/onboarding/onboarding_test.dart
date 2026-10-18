import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sport_xp_4/core/theme/app_theme.dart';
import 'package:sport_xp_4/features/onboarding/domain/onboarding_quiz.dart';
import 'package:sport_xp_4/features/onboarding/domain/onboarding_repository.dart';
import 'package:sport_xp_4/features/onboarding/domain/onboarding_state.dart';
import 'package:sport_xp_4/features/onboarding/presentation/onboarding_page.dart';
import 'package:sport_xp_4/features/onboarding/presentation/onboarding_gate.dart';
import 'package:sport_xp_4/features/onboarding/data/supabase_onboarding_repository.dart';
import 'package:sport_xp_4/features/profile/domain/player_profile.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  List<int> answers;
  bool fail = false;
  bool failLoad = false;
  int saves = 0;
  FakeOnboardingRepository([List<int> initial = const []])
    : answers = [...initial];
  OnboardingState get state => OnboardingState(
    step: answers.length,
    answers: answers,
    displayName: 'Hoàng Nguyễn',
    eloRating: answers.length == 5 ? OnboardingQuiz.initialElo(answers) : null,
    tierName: answers.length == 5 ? OnboardingQuiz.tier(answers).label : null,
  );
  @override
  Future<OnboardingState> load() async {
    if (failLoad) throw StateError('Offline');
    return state;
  }

  @override
  Future<OnboardingState> saveAnswer(int questionIndex, int choiceIndex) async {
    saves++;
    if (fail) throw StateError('Offline');
    answers = [...answers.take(questionIndex), choiceIndex];
    return state;
  }
}

Widget host(
  FakeOnboardingRepository repo, {
  VoidCallback? done,
  GlobalKey? preview,
}) => MaterialApp(
  theme: AppTheme.dark.copyWith(
    textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: AppTheme.dark.primaryTextTheme.apply(
      fontFamily: 'Roboto',
    ),
  ),
  home: RepaintBoundary(
    key: preview,
    child: OnboardingPage(
      initialState: repo.state,
      repository: repo,
      onComplete: done ?? () {},
      onSignOut: () {},
    ),
  ),
);

Future<void> choose(WidgetTester tester, int question, int answer) async {
  final target = find.text(
    OnboardingQuiz.questions[question].choices[answer].label,
  );
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find.byType(Scrollable).last,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: .2);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable)
            .parent
            .parent
            .parent
            .parent
            .parent
            .parent
            .path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    final font = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold', 'black']) {
      font.addFont(
        File('$fonts/roboto-$weight.ttf')
            .readAsBytes()
            .then(ByteData.sublistView),
      );
    }
    await font.load();
    await (FontLoader('MaterialIcons')..addFont(
          File('$fonts/materialicons-regular.otf')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  test('All 768 answer combinations respect 300..850 and exact scoring', () {
    var count = 0;
    for (var a = 0; a < 4; a++) {
      for (var b = 0; b < 4; b++) {
        for (var c = 0; c < 3; c++) {
          for (var d = 0; d < 4; d++) {
            for (var e = 0; e < 4; e++) {
              final answers = [a, b, c, d, e];
              final expected =
                  (300 +
                          [0, 50, 120, 200][a] +
                          [0, 60, 100, 150][b] +
                          [0, 100, 150][c] +
                          [0, 50, 100, 130][d] +
                          [0, 50, 100, 150][e])
                      .clamp(300, 850);
              expect(OnboardingQuiz.initialElo(answers), expected);
              count++;
            }
          }
        }
      }
    }
    expect(count, 768);
    expect(OnboardingQuiz.initialElo([0, 0, 0, 0, 0]), 300);
    expect(OnboardingQuiz.rawElo([3, 3, 2, 3, 3]), 1080);
    expect(OnboardingQuiz.initialElo([3, 3, 2, 3, 3]), 850);
    expect(OnboardingQuiz.initialElo([2, 1, 1, 0, 1]), 630);
    expect(() => OnboardingQuiz.initialElo([0, 0]), throwsArgumentError);
    expect(
      () => OnboardingQuiz.initialElo([0, 0, 3, 0, 0]),
      throwsArgumentError,
    );
  });

  test(
    'Nullable profile rank is an unranked account, never a fabricated zero',
    () {
      final p = PlayerProfile.fromJson({
        'id': 'u',
        'display_name': 'A',
        'elo_rating': null,
        'tier_name': null,
        'trust_score': 100,
        'win_streak': 0,
      });
      expect(p.eloRating, isNull);
      expect(p.tierName, 'Chưa xếp hạng');
    },
  );

  testWidgets(
    'One tap auto-advances; failures preserve step; retry and resume work',
    (tester) async {
      final repo = FakeOnboardingRepository();
      await tester.pumpWidget(host(repo));
      expect(find.text('Bước 1/5'), findsOneWidget);
      await choose(tester, 0, 2);
      expect(find.text('Bước 2/5'), findsOneWidget);
      repo.fail = true;
      await choose(tester, 1, 1);
      expect(find.byKey(const ValueKey('question-1')), findsOneWidget);
      expect(repo.answers, [2]);
      repo.fail = false;
      await tester.scrollUntilVisible(
        find.text('Lưu lại câu trả lời'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Lưu lại câu trả lời'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Bước 3/5'), findsOneWidget);
      // Recreate the page with server-persisted progress.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host(repo));
      await tester.pumpAndSettle();
      expect(find.text('Bước 3/5'), findsOneWidget);
      await tester.tap(find.text('Câu trước'));
      await tester.pumpAndSettle();
      await choose(tester, 1, 0);
      expect(repo.answers, [2, 0]);
      expect(find.text('Bước 3/5'), findsOneWidget);
    },
  );

  testWidgets(
    'Completes with capped player card and explicit unverified status',
    (tester) async {
      final repo = FakeOnboardingRepository();
      var finished = false;
      await tester.pumpWidget(host(repo, done: () => finished = true));
      for (var q = 0; q < 5; q++) {
        await choose(tester, q, [3, 3, 2, 3, 3][q]);
      }
      expect(find.text('850'), findsOneWidget);
      expect(find.text('TB+'), findsOneWidget);
      expect(find.text('Unverified · Chưa xác minh'), findsOneWidget);
      expect(find.text('Hoàng Nguyễn'), findsOneWidget);
      expect(repo.saves, 5);
      await tester.scrollUntilVisible(
        find.text('BẮT ĐẦU LÊN SÂN'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('BẮT ĐẦU LÊN SÂN'));
      expect(finished, true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320px, 200% text and reduced motion remain usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final repo = FakeOnboardingRepository();
    await tester.pumpWidget(host(repo));
    for (var q = 0; q < 5; q++) {
      await choose(tester, q, 0);
      expect(tester.takeException(), isNull);
    }
    await tester.scrollUntilVisible(
      find.text('BẮT ĐẦU LÊN SÂN'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'Supabase repository sends choices only, never a client Elo or user ID',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'onboarding_step': 1,
              'answers': [2],
              'display_name': 'Minh',
              'elo_rating': null,
              'tier_name': null,
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = SupabaseOnboardingRepository(client);
      expect((await repo.load()).step, 1);
      final state = await repo.saveAnswer(0, 2);
      expect(state.answers, [2]);
      expect(requests.first.url.path, '/rest/v1/rpc/get_onboarding_state');
      expect(requests.last.url.path, '/rest/v1/rpc/save_onboarding_answer');
      expect(jsonDecode(requests.last.body), {
        'p_question_index': 0,
        'p_choice_index': 2,
      });
    },
  );

  testWidgets(
    'Auth gate resumes a quiz and opens the app only after completion',
    (tester) async {
      final client = (await tester.runAsync(
        () async => SupabaseClient(
          'https://example.supabase.co',
          'test-public',
          authOptions: const AuthClientOptions(
            autoRefreshToken: false,
            authFlowType: AuthFlowType.implicit,
          ),
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'access_token': 'test-access',
                'refresh_token': 'test-refresh',
                'expires_in': 3600,
                'token_type': 'bearer',
                'user': {
                  'id': 'user-1',
                  'aud': 'authenticated',
                  'email': 'me@example.com',
                  'created_at': '2026-10-18T00:00:00Z',
                  'app_metadata': {},
                  'user_metadata': {},
                },
              }),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      ))!;
      addTearDown(() async => tester.runAsync(client.dispose));
      final repo = FakeOnboardingRepository([2, 1]);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: OnboardingGate(
            client: client,
            repository: repo,
            child: const Scaffold(body: Text('MAIN APP')),
          ),
        ),
      );
      expect(find.text('MAIN APP'), findsNothing);
      expect(find.text('Chào mừng trở lại.'), findsOneWidget);
      await tester.runAsync(
        () => client.auth.signInWithPassword(
          email: 'me@example.com',
          password: 'password',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bước 3/5'), findsOneWidget);
      expect(find.text('MAIN APP'), findsNothing);
      for (var q = 2; q < 5; q++) {
        await choose(tester, q, 0);
      }
      expect(find.text('480'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('BẮT ĐẦU LÊN SÂN'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('BẮT ĐẦU LÊN SÂN'));
      await tester.pumpAndSettle();
      expect(find.text('MAIN APP'), findsOneWidget);
      // A restored completed session must skip the quiz.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingGate(
            client: client,
            repository: repo,
            child: const Scaffold(body: Text('RESTORED APP')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('RESTORED APP'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Capture phone previews for visual review', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preview = GlobalKey();
    final repo = FakeOnboardingRepository();
    await tester.pumpWidget(host(repo, preview: preview));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          preview.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/onboarding-previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    }

    await tester.runAsync(() => capture('question'));
    for (var q = 0; q < 5; q++) {
      await choose(tester, q, [3, 3, 2, 3, 3][q]);
    }
    await tester.runAsync(() => capture('result'));
  });
}
