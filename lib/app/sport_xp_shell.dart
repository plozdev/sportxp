import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/feed/domain/match_summary.dart';
import '../features/feed/presentation/feed_page.dart';
import '../features/feed/presentation/record_match_sheet.dart';
import '../features/matchmaking/domain/live_match_repository.dart';
import '../features/matchmaking/domain/match_room.dart';
import '../features/matchmaking/presentation/create_match_sheet.dart';
import '../features/matchmaking/presentation/matchmaking_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/player_profile.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/rankings/presentation/leaderboard_page.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/bento_card.dart';
import '../features/rooms/data/managed_room_repository.dart';
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
  Future<List<MatchSummary>>? _feed;
  Future<List<MatchRoom>>? _rooms;
  Future<List<PlayerProfile>>? _leaders;
  Future<PlayerProfile?> _profile = Future.value(null);
  String? _userId, _joiningRoom;
  bool _signingOut = false;
  int _index = 0;
  int _roomRefresh = 0;
  static const _roomsV2 = bool.fromEnvironment('ROOMS_V2_ENABLED');

  @override
  void initState() {
    super.initState();
    _userId = widget.client?.auth.currentUser?.id;
    _reload();
    _auth = widget.client?.auth.onAuthStateChange.listen(
      (state) {
        final id = state.session?.user.id;
        if (!mounted || id == _userId) return;
        setState(() {
          _userId = id;
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
      _leaders = _observe(profiles.leaderboard());
      _profile = _observe(profiles.currentProfile());
    }
    final matches = widget.matches;
    if (matches != null) {
      _feed = _observe(matches.feed());
      if (!_roomsV2) _rooms = _observe(matches.openRooms());
    }
  }

  // A request can fail before the next frame attaches its FutureBuilder.
  // Observe immediately; retain the original future for error/retry UI.
  Future<T> _observe<T>(Future<T> future) {
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
    return future;
  }

  void _refresh() => setState(_reload);
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
    if (_roomsV2 && widget.client != null) {
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RoomEditorPage(repository: ManagedRoomRepository(widget.client!)),
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
    appBar: AppBar(title: const Text('SPORTXP')),
    body: SafeArea(
      child: IndexedStack(
        index: _index,
        children: [
          _feed == null
              ? _pending(feed: true)
              : FeedPage(
                  matches: _feed!,
                  onRecord: _record,
                  onRefresh: _refresh,
                ),
          _roomsV2 && widget.client != null
              ? ManagedRoomsPage(
                  repository: ManagedRoomRepository(widget.client!),
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
          _leaders == null
              ? _pending()
              : LeaderboardPage(players: _leaders!, onRefresh: _refresh),
          ProfilePage(
            profile: _profile,
            isSignedIn: _userId != null,
            onSignOut: _signOut,
            onRefresh: _refresh,
            repository: widget.client != null
                ? ProfileRepository(widget.client!)
                : null,
          ),
        ],
      ),
    ),
    floatingActionButton: _index < 2
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
        _reload();
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.sports_tennis_outlined),
          selectedIcon: Icon(Icons.sports_tennis, color: AppColors.primary),
          label: 'Kèo đấu',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events, color: AppColors.primary),
          label: 'Xếp hạng',
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
