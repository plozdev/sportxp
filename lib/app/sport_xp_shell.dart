import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/feed/presentation/record_match_sheet.dart';
import '../features/feed/data/mock_activity_repository.dart';
import '../features/matchmaking/domain/live_match_repository.dart';
import '../features/matchmaking/domain/match_room.dart';
import '../features/matchmaking/presentation/create_match_sheet.dart';
import '../features/matchmaking/presentation/matchmaking_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/player_profile.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/rankings/presentation/leaderboard_page.dart';
import '../features/rankings/data/mock_leaderboard_repository.dart';
import '../features/rankings/data/supabase_leaderboard_repository.dart';
import '../features/tournaments/presentation/tournaments_page.dart';
import '../features/notifications/data/notice_repository.dart';
import '../features/notifications/presentation/notification_modal_sheet.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/bento_card.dart';
import '../features/rooms/data/managed_room_repository.dart';
import '../features/rooms/data/mock_room_repository.dart';
import '../features/rooms/domain/room_repository.dart';
import '../features/rooms/presentation/managed_rooms_page.dart';
import '../features/rooms/presentation/room_editor_page.dart';

class SportXpShell extends StatefulWidget {
  const SportXpShell({super.key, this.client, this.matches, this.startupError});
  final SupabaseClient? client;
  final LiveMatchRepository? matches;
  final String? startupError;
  @override
  State<SportXpShell> createState() => _SportXpShellState();
}

class _SportXpShellState extends State<SportXpShell> {
  StreamSubscription<AuthState>? _auth;
  Future<List<MatchRoom>>? _rooms;
  Future<List<PlayerProfile>>? _leaders;
  Future<PlayerProfile?> _profile = Future.value(null);
  String? _userId, _joiningRoom;
  bool _signingOut = false;
  int _index = 0;
  int _roomRefresh = 0;
  static const _roomsV2 = bool.fromEnvironment('ROOMS_V2_ENABLED');
  static const _mockRooms = bool.fromEnvironment(
    'ROOMS_MOCK_ENABLED',
    defaultValue: false,
  );
  MockRoomRepository? _sandbox;
  MockActivityRepository? _activities;
  MockLeaderboardRepository? _mockLeaderboard;
  bool get _managed => _mockRooms || _roomsV2;
  RoomRepository get _roomRepository =>
      _mockRooms ? _sandbox! : ManagedRoomRepository(widget.client!);

  void _bindSandbox() {
    final id = _userId;
    if (id == null) {
      _sandbox = null;
      _activities = null;
      _mockLeaderboard = null;
      return;
    }
    if (_sandbox?.userId != id) {
      _sandbox = MockRoomRepository(userId: id);
      _activities = MockActivityRepository(_sandbox!);
      _mockLeaderboard = MockLeaderboardRepository(_sandbox!);
    }
  }

  @override
  void initState() {
    super.initState();
    _userId = widget.client?.auth.currentUser?.id;
    _bindSandbox();
    _reload();
    _auth = widget.client?.auth.onAuthStateChange.listen(
      (state) {
        final id = state.session?.user.id;
        if (!mounted || id == _userId) return;
        setState(() {
          _userId = id;
          _bindSandbox();
          _reload();
        });
      },
      onError: (_) {
        if (mounted) {
          _message('Phiên đăng nhập gặp lỗi. Vui lòng đăng nhập lại.');
        }
      },
    );
  }

  void _reload() {
    if (widget.client?.auth.currentSession == null) return;
    _roomRefresh++;
    final client = widget.client;
    if (client != null) {
      final profiles = ProfileRepository(client);
      if (!_mockRooms) _leaders = _observe(profiles.leaderboard());
      _profile = _observe(profiles.currentProfile());
      final sandbox = _sandbox;
      unawaited(
        _profile.then<void>((p) {
          if (p != null && identical(sandbox, _sandbox)) {
            final changed =
                sandbox != null &&
                (sandbox.people[sandbox.userId] != p.displayName ||
                    (p.eloRating != null &&
                        sandbox.ratings[sandbox.userId] != p.eloRating));
            sandbox?.updateProfile(p.displayName, p.eloRating);
            if (_mockRooms && mounted && changed) _refreshSandbox();
          }
        }, onError: (Object _, StackTrace _) {}),
      );
    }
    final matches = widget.matches;
    if (matches != null) {
      if (!_managed) _rooms = _observe(matches.openRooms());
    }
  }

  // A request can fail before the next frame attaches its FutureBuilder.
  // Observe immediately; retain the original future for error/retry UI.
  Future<T> _observe<T>(Future<T> future) {
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
    return future;
  }

  void _refresh() => setState(_reload);
  void _refreshSandbox() => setState(() => _roomRefresh++);

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _ensureAuth() async {
    final session = widget.client?.auth.currentSession;
    return session != null && !session.isExpired;
  }

  Future<void> _create() async {
    if (!await _ensureAuth() || !mounted) return;
    if (_managed && widget.client != null) {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RoomEditorPage(repository: _roomRepository),
        ),
      );
      if (mounted && success == true) {
        setState(() {
          _index = 1;
          _reload();
        });
      }
      return;
    }
    final matches = widget.matches;
    if (matches == null) {
      _message(_schemaMessage);
      return;
    }
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => CreateMatchSheet(
        loadCourts: matches.courts,
        onSubmit: matches.createRoom,
      ),
    );
    if (mounted && success == true) {
      setState(() {
        _index = 1;
        _reload();
      });
    }
  }

  Future<void> _record() async {
    if (!await _ensureAuth() || !mounted) return;
    if (_mockRooms) {
      setState(() => _index = 1);
      _message(
        'Mô phỏng: mở Buổi của tôi → buổi đang chơi → Trận đấu / Điểm danh.',
      );
      return;
    }
    final matches = widget.matches;
    if (matches == null) {
      _message(_schemaMessage);
      return;
    }
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => RecordMatchSheet(onSubmit: matches.recordMatch),
    );
    // Refresh after commit; a failed read must never cause a second RPC write.
    if (mounted && success == true) _refresh();
  }

  Future<void> _join(MatchRoom room) async {
    if (_joiningRoom != null || !await _ensureAuth() || !mounted) return;
    final matches = widget.matches;
    if (matches == null) return;
    setState(() => _joiningRoom = room.id);
    try {
      await matches.joinRoom(room.id);
      if (mounted) _message('Đã vào kèo.');
    } catch (_) {
      if (mounted) {
        _message('Không thể vào kèo. Kèo có thể đã đầy; vui lòng cập nhật.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _joiningRoom = null;
          _rooms = _observe(matches.openRooms());
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    _signingOut = true;
    try {
      await widget.client?.auth.signOut();
    } catch (_) {
      if (mounted) _message('Không thể đăng xuất. Vui lòng thử lại.');
    } finally {
      _signingOut = false;
    }
  }

  static const _schemaMessage =
      'Chưa cấu hình kết nối Supabase. Vui lòng kiểm tra cấu hình ứng dụng.';
  Widget _pending({bool feed = false}) => PageContent(
    children: [
      if (feed)
        Text(
          'Mọi set cầu đều được\nđịnh danh và ghi nhận.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      BentoCard(child: Text(widget.startupError ?? _schemaMessage)),
      if (feed)
        TextButton.icon(
          onPressed: _record,
          icon: const Icon(Icons.add),
          label: const Text('Ghi nhận set cầu'),
        ),
    ],
  );

  @override
  void dispose() {
    _auth?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
      ),
      title: Row(
        children: [
          const Text(
            'SPORTXP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),

        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            if (widget.client != null) {
              NotificationModalSheet.show(
                context,
                SupabaseNoticeRepository(widget.client!),
                onNoticesUpdated: () => setState(() {}),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không có thông báo mới.'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
          icon: const Icon(Icons.notifications_none_rounded, size: 22),
          tooltip: 'Thông báo',
        ),
      ],
    ),
    body: SafeArea(
      child: IndexedStack(
        index: _index,
        children: [
          _managed && widget.client != null && (!_mockRooms || _sandbox != null)
              ? ManagedRoomsPage(
                  repository: _roomRepository,
                  refreshToken: _roomRefresh,
                )
              : _rooms == null
              ? _pending()
              : MatchmakingPage(
                  rooms: _rooms!,
                  userId: _userId,
                  joiningRoomId: _joiningRoom,
                  onJoin: _join,
                  onRefresh: _refresh,
                ),
          _mockRooms && _sandbox != null
              ? LeaderboardPage(
                  repository: _mockLeaderboard,
                  refreshToken: _roomRefresh,
                  onRefresh: _refreshSandbox,
                  isMock: true,
                  selectedPlayerId: _sandbox!.actorId,
                )
              : _leaders == null
              ? _pending()
              : LeaderboardPage(
                  repository: widget.client != null
                      ? SupabaseLeaderboardRepository(widget.client!)
                      : null,
                  players: _leaders,
                  onRefresh: _refresh,
                  selectedPlayerId: _userId,
                ),
          const TournamentsPage(),
          ProfilePage(
            accountSwitcher: null,
            profile: _profile,
            isSignedIn: _userId != null,
            onSignOut: _signOut,
            onRefresh: _refresh,
            repository: widget.client != null
                ? ProfileRepository(widget.client!)
                : null,
            activityRepository: _activities,
            roomRepository: _sandbox,
            refreshToken: _roomRefresh,
          ),
        ],
      ),
    ),
    floatingActionButton: _index == 0
        ? FloatingActionButton.extended(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('TẠO KÈO MỚI'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() {
        _index = value;
        _roomRefresh++;
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sports_tennis_outlined),
          selectedIcon: Icon(Icons.sports_tennis, color: AppColors.primary),
          label: 'Tìm kèo',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard, color: AppColors.primary),
          label: 'Xếp hạng',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events, color: AppColors.primary),
          label: 'Giải đấu',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Hồ sơ',
        ),
      ],
    ),
  );
}