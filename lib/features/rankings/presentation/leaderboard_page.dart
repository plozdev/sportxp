import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../matchmaking/domain/court.dart';
import '../../profile/domain/player_profile.dart';
import '../domain/leaderboard_repository.dart';
import '../domain/rank_tier.dart';
import 'widgets/court_picker_sheet.dart';
import 'widgets/duolingo_rank_row.dart';
import 'widgets/my_fixed_standing_bar.dart';
import 'widgets/player_detail_modal.dart';

enum LeaderboardViewMode {
  all('Tất cả'),
  nearMe('Quanh bạn (±5)');

  const LeaderboardViewMode(this.label);
  final String label;
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({
    super.key,
    this.players,
    this.repository,
    required this.onRefresh,
    this.isMock = false,
    this.selectedPlayerId,
    this.initialCourtId,
    this.refreshToken = 0,
  });

  final Future<List<PlayerProfile>>? players;
  final LeaderboardRepository? repository;
  final VoidCallback onRefresh;
  final bool isMock;
  final String? selectedPlayerId;
  final String? initialCourtId;
  final int refreshToken;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _myRankKey = GlobalKey();
  int _request = 0;

  String _selectedCourtId = '';
  List<Court> _courts = const [];
  List<PlayerProfile> _allPlayers = const [];
  List<PlayerProfile> _displayPlayers = const [];
  PlayerCourtRank? _userCourtRank;
  LeaderboardViewMode _viewMode = LeaderboardViewMode.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourtId != null) {
      _selectedCourtId = widget.initialCourtId!;
    }
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant LeaderboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.players != oldWidget.players ||
        widget.repository != oldWidget.repository ||
        widget.refreshToken != oldWidget.refreshToken ||
        widget.selectedPlayerId != oldWidget.selectedPlayerId) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final request = ++_request;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Tải danh sách sân
      if (widget.repository != null) {
        final courts = await widget.repository!.getCourts();
        if (mounted && request == _request && courts.isNotEmpty) {
          _courts = courts;
          if (_selectedCourtId.isEmpty || !_courts.any((c) => c.id == _selectedCourtId)) {
            _selectedCourtId = courts.first.id;
          }
        }
      }

      // 2. Tải danh sách vận động viên của sân
      List<PlayerProfile> list;
      if (widget.repository != null) {
        list = await widget.repository!.getCourtLeaderboard(
          courtId: _selectedCourtId,
        );
      } else if (widget.players != null) {
        list = await widget.players!;
      } else {
        list = const [];
      }

      // 3. Tính toán vị trí xếp hạng của người dùng hiện tại
      PlayerCourtRank? rankInfo;
      final currentUserId = widget.selectedPlayerId ?? 'me';
      if (widget.repository != null) {
        rankInfo = await widget.repository!.getPlayerCourtRank(
          playerId: currentUserId,
          courtId: _selectedCourtId,
        );
      } else {
        final index = list.indexWhere((p) => p.id == currentUserId);
        if (index != -1) {
          final player = list[index];
          int? pointsToNext;
          String? nextName;
          if (index > 0) {
            final above = list[index - 1];
            pointsToNext = ((above.eloRating ?? 0) - (player.eloRating ?? 0))
                .abs();
            if (pointsToNext == 0) pointsToNext = 1;
            nextName = above.displayName;
          }
          rankInfo = PlayerCourtRank(
            rank: index + 1,
            totalPlayers: list.length,
            courtName: _currentCourtName,
            courtId: _selectedCourtId,
            pointsToNextRank: pointsToNext,
            nextPlayerName: nextName,
            isPodium: index < 3,
            tier: player.eloRating != null
                ? RankTier.fromElo(player.eloRating!)
                : null,
            elo: player.eloRating,
            rankDelta: player.rankDelta,
          );
        }
      }

      if (mounted && request == _request) {
        setState(() {
          _allPlayers = list;
          _userCourtRank = rankInfo;
          _isLoading = false;
        });
        _applyViewMode();
      }
    } catch (e) {
      if (mounted && request == _request) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải bảng xếp hạng: $e';
        });
      }
    }
  }

  void _applyViewMode() {
    if (_viewMode == LeaderboardViewMode.all) {
      _displayPlayers = _allPlayers;
    } else {
      // Quanh bạn (±5 người)
      final currentUserId = widget.selectedPlayerId ?? 'me';
      final index = _allPlayers.indexWhere((p) => p.id == currentUserId);
      if (index == -1) {
        _displayPlayers = _allPlayers.take(11).toList();
      } else {
        final start = (index - 5).clamp(0, _allPlayers.length);
        final end = (index + 6).clamp(0, _allPlayers.length);
        _displayPlayers = _allPlayers.sublist(start, end);
      }
    }
  }

  void _onSelectCourt(String courtId) {
    if (_selectedCourtId == courtId) return;
    setState(() {
      _selectedCourtId = courtId;
      _viewMode = LeaderboardViewMode.all;
    });
    _fetchData();
  }

  void _scrollToMyRank() {
    final context = _myRankKey.currentContext;
    if (context == null) {
      setState(() {
        _viewMode = LeaderboardViewMode.nearMe;
        _applyViewMode();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _myRankKey.currentContext != null) _scrollToMyRank();
      });
      return;
    }
    Scrollable.ensureVisible(
      context,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  String get _currentCourtName {
    final found = _courts.where((c) => c.id == _selectedCourtId).firstOrNull;
    return found?.name ?? (_courts.isNotEmpty ? _courts.first.name : 'Sân thi đấu');
  }

  PlayerProfile? get _currentUserProfile {
    final currentUserId = widget.selectedPlayerId ?? 'me';
    final found = _allPlayers.where((p) => p.id == currentUserId).firstOrNull;
    if (found != null) return found;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading && _allPlayers.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null && _allPlayers.isEmpty
          ? _buildErrorView()
          : Column(
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                // Phần danh sách cuộn
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTokens.contentWidth,
                      ),
                      child: _buildLeaderboardContent(),
                    ),
                  ),
                ),
                // Vùng cố định riêng biệt hiển thị vị trí của bạn, KHÔNG che bất kỳ hàng nào
                if (_userCourtRank != null && _currentUserProfile != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppTokens.contentWidth,
                      ),
                      child: MyFixedStandingBar(
                        userProfile: _currentUserProfile!,
                        rankSummary: _userCourtRank!,
                        onScrollToMyRank: _scrollToMyRank,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã có lỗi xảy ra',
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                widget.onRefresh();
                _fetchData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(PlayerProfile player, int rank) {
    PlayerDetailModal.show(
      context,
      player: player,
      rank: rank,
      isCurrentUser: player.id == widget.selectedPlayerId,
    );
  }

  Widget _buildLeaderboardContent() {
    final currentId = widget.selectedPlayerId ?? 'me';
    final podium =
        _viewMode == LeaderboardViewMode.all && _allPlayers.length >= 3;
    final players = podium ? _displayPlayers.skip(3).toList() : _displayPlayers;
    return ListView(
      key: const PageStorageKey('court-leaderboard-scroll'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                widget.onRefresh();
                _fetchData();
              },
              tooltip: 'Cập nhật bảng xếp hạng',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            key: const Key('court_picker_button'),
            leading: const Icon(
              Icons.stadium_outlined,
              color: AppColors.primary,
            ),
            title: Text(
              _currentCourtName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${_allPlayers.length} tay vợt',
            ),
            trailing: const Icon(Icons.expand_more),
            onTap: () => CourtPickerSheet.show(
              context,
              courts: _courts,
              selectedCourtId: _selectedCourtId,
              onSelectCourt: _onSelectCourt,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (podium) ...[
          const Text(
            'Top tay vợt tại sân',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final index in [1, 0, 2])
                Expanded(child: _podiumPlayer(_allPlayers[index], index + 1)),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (_userCourtRank?.pointsToNextRank != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Còn ${_userCourtRank!.pointsToNextRank} Elo để vượt ${_userCourtRank!.nextPlayerName ?? 'vị trí phía trên'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        SegmentedButton<LeaderboardViewMode>(
          segments: [
            for (final mode in LeaderboardViewMode.values)
              ButtonSegment(value: mode, label: Text(mode.label)),
          ],
          selected: {_viewMode},
          showSelectedIcon: false,
          onSelectionChanged: (values) => setState(() {
            _viewMode = values.first;
            _applyViewMode();
          }),
        ),
        const SizedBox(height: 14),
        if (players.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa có vận động viên trong bảng xếp hạng sân này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        if (players.isNotEmpty)
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final player in players)
                  Builder(
                    key: player.id == currentId
                        ? _myRankKey
                        : ValueKey(player.id),
                    builder: (_) => DuolingoRankRow(
                      player: player,
                      rank: _allPlayers.indexOf(player) + 1,
                      isCurrentUser: player.id == currentId,
                      showDivider: player != players.last,
                      onTap: () =>
                          _openPlayer(player, _allPlayers.indexOf(player) + 1),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _podiumPlayer(PlayerProfile player, int rank) {
    final champion = rank == 1;
    final color = champion ? AppColors.streak : AppColors.primary;
    return InkWell(
      key: player.id == (widget.selectedPlayerId ?? 'me')
          ? _myRankKey
          : ValueKey('podium-${player.id}'),
      onTap: () => _openPlayer(player, rank),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (champion)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.streak,
                  size: 25,
                ),
              ),
            CircleAvatar(
              radius: champion ? 31 : 25,
              backgroundColor: AppColors.mint,
              child: ClipOval(
                child: player.avatarUrl != null
                    ? Image.network(
                        player.avatarUrl!,
                        width: champion ? 62 : 50,
                        height: champion ? 62 : 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Text(player.initials),
                      )
                    : Text(
                        player.initials,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              player.displayName.replaceAll(' · giả lập', ''),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${player.eloRating ?? '—'} Elo',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: champion ? 64 : (rank == 2 ? 46 : 36),
              alignment: Alignment.center,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                border: Border(top: BorderSide(color: color, width: 3)),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
