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

  String _selectedCourtId = 'court-a';
  List<Court> _courts = const [
    Court(id: 'court-a', name: 'Sân Đào Duy Anh', distanceKm: 1.8),
    Court(id: 'court-b', name: 'Sân Bình Thạnh', distanceKm: 4.2),
    Court(id: 'court-c', name: 'Sân Thủ Đức', distanceKm: 8.5),
  ];
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
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String get _currentCourtName {
    final found = _courts.where((c) => c.id == _selectedCourtId).firstOrNull;
    return found?.name ?? 'Sân Đào Duy Anh';
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

  Widget _buildLeaderboardContent() {
    final currentUserId = widget.selectedPlayerId ?? 'me';

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        // 1. Header Bảng Xếp Hạng Theo Sân - Tinh gọn, chống overflow hoàn toàn
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stadium_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'BẢNG XẾP HẠNG THEO SÂN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    key: const Key('court_picker_button'),
                    onTap: () {
                      CourtPickerSheet.show(
                        context,
                        courts: _courts,
                        selectedCourtId: _selectedCourtId,
                        onSelectCourt: _onSelectCourt,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(100),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Đổi sân',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      widget.onRefresh();
                      _fetchData();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    tooltip: 'Cập nhật bảng xếp hạng',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentCourtName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_allPlayers.length} tay vợt',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (widget.isMock) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 11,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'BẢNG XẾP HẠNG GIẢ LẬP · Dữ liệu mẫu thử nghiệm',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Hero Card: Tiêu điểm mục tiêu theo đuổi & Câu chuyện gần
        if (_userCourtRank != null && _currentUserProfile != null)
          _buildFocusHeroCard(_userCourtRank!, _currentUserProfile!),

        // 3. View Mode Tabs (Tất cả / Quanh bạn)
        Row(
          children: [
            for (final mode in LeaderboardViewMode.values) ...[
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _viewMode = mode;
                      _applyViewMode();
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _viewMode == mode
                          ? AppColors.primary.withAlpha(25)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _viewMode == mode
                            ? AppColors.primary
                            : AppColors.border,
                        width: _viewMode == mode ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _viewMode == mode
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _viewMode == mode
                            ? AppColors.text
                            : AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              if (mode != LeaderboardViewMode.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),

        const SizedBox(height: 12),

        // 4. Seamless Leaderboard List (Danh sách liền mạch, không chia thành các huy hiệu rời rạc)
        if (_displayPlayers.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Chưa có vận động viên trong bảng xếp hạng sân này.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _displayPlayers.length; i++) ...[
                  Builder(
                    key: _displayPlayers[i].id == currentUserId
                        ? _myRankKey
                        : ValueKey(_displayPlayers[i].id),
                    builder: (ctx) {
                      final player = _displayPlayers[i];
                      final realRank = _allPlayers.indexOf(player) + 1;
                      final isUser = player.id == currentUserId;
                      final isLast = i == _displayPlayers.length - 1;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DuolingoRankRow(
                            player: player,
                            rank: realRank,
                            isCurrentUser: isUser,
                            showDivider:
                                !isLast &&
                                !(realRank == 3 &&
                                    _viewMode == LeaderboardViewMode.all),
                            onTap: () {
                              PlayerDetailModal.show(
                                context,
                                player: player,
                                rank: realRank,
                                isCurrentUser: isUser,
                              );
                            },
                          ),

                          // Top tay vợt tại sân (thay thế cho dòng Khu vực thăng hạng Top 3 cũ)
                          if (_viewMode == LeaderboardViewMode.all &&
                              realRank == 3 &&
                              !isLast) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              color: AppColors.background.withAlpha(140),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_outlined,
                                    size: 13,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Top tay vợt tại sân',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Divider(
                                      color: const Color(0xFFF59E0B)
                                          .withAlpha(60),
                                      thickness: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Khối Hero "Tiêu điểm & Câu chuyện gần" giúp người chơi có mục tiêu theo đuổi tức thì
  Widget _buildFocusHeroCard(
    PlayerCourtRank rankInfo,
    PlayerProfile userProfile,
  ) {
    final elo = userProfile.eloRating ?? 750;
    final tier = RankTier.fromElo(elo);
    final nextProgress = userProfile.nextTierProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(90), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.primary.withAlpha(14)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tiêu điểm & Chuyển động thứ hạng
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.track_changes,
                  size: 13,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'MỤC TIÊU THEO ĐUỔI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              _buildRankDeltaBadge(rankInfo.rankDelta),
            ],
          ),
          const SizedBox(height: 10),

          // Câu chuyện gần: Vị trí & Khoảng cách đối thủ liền kề
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Bạn đang ',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        children: [
                          TextSpan(
                            text: '#${rankInfo.rank}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text: ' tại ${rankInfo.courtName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (rankInfo.rank == 1) ...[
                      const Text(
                        'Bạn đang dẫn đầu sân! Giữ vững phong độ thi đấu.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ] else if (rankInfo.pointsToNextRank != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'Cách vị trí #${rankInfo.rank - 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                                children: [
                                  if (rankInfo.nextPlayerName != null)
                                    TextSpan(
                                      text: ' (${rankInfo.nextPlayerName})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  TextSpan(
                                    text: ': ${rankInfo.pointsToNextRank} Elo',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Mốc trình kế tiếp (Next Skill Tier)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background.withAlpha(160),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.military_tech_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Mốc trình: ${tier.label} → ${nextProgress.nextTier}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      nextProgress.pointsNeeded > 0
                          ? 'Cần +${nextProgress.pointsNeeded} Elo'
                          : 'Đỉnh mốc',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: nextProgress.progress,
                    minHeight: 5,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${tier.label} (${tier.minimumElo})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      '$elo Elo hiện tại',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${nextProgress.nextTier} (${nextProgress.targetElo})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Gamification: Mục tiêu tuần riêng (không trộn Elo) & Thành tích ý nghĩa
          Row(
            children: [
              // 1. Mục tiêu tuần riêng
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(130),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 12,
                            color: Color(0xFF60A5FA),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Mục tiêu tuần',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF60A5FA),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rankInfo.weeklyMatchesTarget > 0
                            ? 'Chơi ${rankInfo.weeklyMatchesTarget} buổi (${rankInfo.weeklyMatchesPlayed}/${rankInfo.weeklyMatchesTarget})'
                            : 'Chưa đặt mục tiêu tuần',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Duy trì lịch · Không cộng Elo',
                        style: TextStyle(fontSize: 9, color: AppColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Thành tích có ý nghĩa
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(130),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 12,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Thành tích ý nghĩa',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF59E0B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rankInfo.recentAchievement ??
                            'Chưa có thành tích xác nhận',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        userProfile.isCalibrated
                            ? 'Đã hoàn tất phân hạng'
                            : '${userProfile.placementMatchesCompleted}/5 trận phân hạng',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankDeltaBadge(int delta) {
    if (delta > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(25),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward, size: 11, color: Color(0xFF10B981)),
            const SizedBox(width: 2),
            Text(
              '↑ $delta bậc so với tuần trước',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else if (delta < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(25),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_downward,
              size: 11,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 2),
            Text(
              '↓ ${delta.abs()} bậc so với tuần trước',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          '– Giữ vững thứ hạng',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      );
    }
  }
}
