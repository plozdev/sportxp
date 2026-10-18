import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../matchmaking/domain/court.dart';
import '../../profile/domain/player_profile.dart';
import '../domain/leaderboard_repository.dart';
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
  });

  final Future<List<PlayerProfile>>? players;
  final LeaderboardRepository? repository;
  final VoidCallback onRefresh;
  final bool isMock;
  final String? selectedPlayerId;
  final String? initialCourtId;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ScrollController _scrollController = ScrollController();

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Tải danh sách sân
      if (widget.repository != null) {
        final courts = await widget.repository!.getCourts();
        if (mounted && courts.isNotEmpty) {
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
          rankInfo = PlayerCourtRank(
            rank: index + 1,
            totalPlayers: list.length,
            courtName: _currentCourtName,
            courtId: _selectedCourtId,
            isPodium: index < 3,
            elo: list[index].eloRating,
          );
        }
      }

      if (mounted) {
        setState(() {
          _allPlayers = list;
          _userCourtRank = rankInfo;
          _isLoading = false;
        });
        _applyViewMode();
      }
    } catch (e) {
      if (mounted) {
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
    final currentUserId = widget.selectedPlayerId ?? 'me';
    final index = _displayPlayers.indexWhere((p) => p.id == currentUserId);
    if (index != -1 && _scrollController.hasClients) {
      final targetOffset = index * 70.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
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
    if (_allPlayers.isNotEmpty) return _allPlayers.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _buildErrorView()
          : Column(
              children: [
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
        // 1. Header Bảng Xếp Hạng Theo Sân rõ ràng
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.stadium_outlined,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'BẢNG XẾP HẠNG THEO SÂN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
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
                        icon: const Icon(Icons.refresh, color: AppColors.muted),
                        tooltip: 'Cập nhật bảng xếp hạng',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currentCourtName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Xếp hạng riêng cho các tay vợt thi đấu tại sân này · ${_allPlayers.length} tay vợt',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Mock Notice (nếu có)
        if (widget.isMock) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: AppColors.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BẢNG XẾP HẠNG GIẢ LẬP · Elo và chuỗi thắng là dữ liệu mẫu, không cập nhật DB',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. View Mode Tabs (Tất cả / Quanh bạn) - Duolingo / Sports Standard
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
                    padding: const EdgeInsets.symmetric(vertical: 9),
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

        const SizedBox(height: 14),

        // 3. Duolingo Clean Leaderboard List
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
          for (var i = 0; i < _displayPlayers.length; i++) ...[
            Builder(
              builder: (ctx) {
                final player = _displayPlayers[i];
                final realRank = _allPlayers.indexOf(player) + 1;
                final isUser = player.id == currentUserId;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DuolingoRankRow(
                      player: player,
                      rank: realRank,
                      isCurrentUser: isUser,
                      onTap: () {
                        PlayerDetailModal.show(
                          context,
                          player: player,
                          rank: realRank,
                          isCurrentUser: isUser,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Duolingo Promotion Zone Divider Line sau Top 3
                    if (_viewMode == LeaderboardViewMode.all && realRank == 3) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFFFD700).withAlpha(100),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 12,
                                  color: Color(0xFFFFD700),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'KHU VỰC THĂNG HẠNG (TOP 3)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFFFFD700).withAlpha(230),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: const Color(0xFFFFD700).withAlpha(100),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}
