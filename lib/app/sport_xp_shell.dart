import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/feed/presentation/feed_page.dart';
import '../features/matchmaking/application/match_controller.dart';
import '../features/matchmaking/data/in_memory_match_repository.dart';
import '../features/matchmaking/presentation/create_match_sheet.dart';
import '../features/matchmaking/presentation/matchmaking_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/tournaments/presentation/tournaments_page.dart';

class SportXpShell extends StatefulWidget {
  const SportXpShell({super.key});
  @override
  State<SportXpShell> createState() => _SportXpShellState();
}

class _SportXpShellState extends State<SportXpShell> {
  late final MatchController _matches;
  int _index = 0;
  @override
  void initState() {
    super.initState();
    _matches = MatchController(InMemoryMatchRepository())..load();
  }

  @override
  void dispose() {
    _matches.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('SPORTXP'),
      actions: const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('BẢN DEMO', style: AppTokens.label),
        ),
      ],
    ),
    body: SafeArea(
      child: IndexedStack(
        index: _index,
        children: [
          const FeedPage(),
          MatchmakingPage(controller: _matches),
          const TournamentsPage(),
          const ProfilePage(),
        ],
      ),
    ),
    floatingActionButton: _index < 2
        ? FloatingActionButton.extended(
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => CreateMatchSheet(controller: _matches),
              );
              if (created == true && mounted) setState(() => _index = 1);
            },
            icon: const Icon(Icons.add),
            label: const Text('TẠO KÈO MỚI'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
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
