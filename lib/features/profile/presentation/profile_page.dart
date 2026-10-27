import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/profile_repository.dart';
import '../domain/player_profile.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/passport_sheet.dart';
import '../../social/data/social_repository.dart';
import '../../social/presentation/connections_page.dart';
import '../../social/presentation/scan_profile_page.dart';
import '../../auth/presentation/auth_page.dart';
import '../../feed/domain/activity.dart';
import '../../feed/presentation/activity_detail_page.dart';
import '../../feed/presentation/widgets/activity_share_sheet.dart';
import '../../feed/presentation/widgets/badminton_court_canvas.dart';
import '../../rooms/domain/room_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.isSignedIn,
    required this.onSignOut,
    required this.onRefresh,
    this.repository,
    this.accountSwitcher,
    this.activityRepository,
    this.roomRepository,
    this.refreshToken,
  });

  final Future<PlayerProfile?> profile;
  final bool isSignedIn;
  final VoidCallback onSignOut, onRefresh;
  final ProfileRepository? repository;
  final Widget? accountSwitcher;
  final ActivityRepository? activityRepository;
  final RoomRepository? roomRepository;
  final int? refreshToken;

  void _openPassport(BuildContext context, PlayerProfile player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassportSheet(profile: player),
    );
  }

  Future<void> _openEditProfile(
    BuildContext context,
    PlayerProfile player,
  ) async {
    if (repository == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        profile: player,
        loadCourts: repository!.loadCourts,
        onSave: (name, courtId) =>
            repository!.updateProfile(displayName: name, homeCourtId: courtId),
      ),
    );
    if (updated == true) onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return AuthPage(client: repository?.client);
    }

    final content = AsyncPanel<PlayerProfile?>(
      future: profile,
      onRetry: onRefresh,
      builder: (player) {
        if (player == null) {
          return PageContent(
            children: [
              const BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ chưa khả dụng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bạn đã đăng nhập nhưng chưa tải được hồ sơ. Hãy thử tải lại hoặc đăng xuất để đăng nhập lại.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('TẢI LẠI HỒ SƠ'),
              ),
              OutlinedButton(
                onPressed: onSignOut,
                child: const Text('ĐĂNG XUẤT'),
              ),
            ],
          );
        }

        return PageContent(
          children: [
            // 1. ATHLETE IDENTITY HEADER (Tích hợp ELO & Trạng thái phân hạng / Tiến trình thăng hạng)
            _AthleteHeaderCard(
              player: player,
              onViewPassport: () => _openPassport(context, player),
              onEdit: repository != null
                  ? () => _openEditProfile(context, player)
                  : null,
            ),

            // 2. CHỈ SỐ PHONG ĐỘ & UY TÍN (Chuỗi thắng & Điểm uy tín gộp trong 1 Bento Card)
            _PerformanceMetricsCard(player: player),

            // 3. NHẬT KÝ THI ĐẤU (Strava Athlete Diary & Session History)
            if (activityRepository != null)
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: const Text('Nhật ký thi đấu'),
                subtitle: const Text(
                  'Buổi đã chơi, kết quả và hoạt động của bạn',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Nhật ký thi đấu')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: _MatchDiarySection(
                          activityRepository: activityRepository!,
                          roomRepository: roomRepository,
                          refreshToken: refreshToken,
                          onProfileRefresh: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 4. KẾT NỐI & QUYỀN RIÊNG TƯ
            if (repository != null && player.publicId != null)
              BentoCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Bạn bè và lời mời'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConnectionsPage(
                            repository: SocialRepository(repository!.client),
                            onOpen: (id) async {
                              await Navigator.of(context).pushNamed('/p/$id');
                            },
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.qr_code_scanner),
                      title: const Text('Quét mã / Mở link hồ sơ'),
                      onTap: () async {
                        final id = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => const ScanProfilePage(),
                          ),
                        );
                        if (id != null && context.mounted) {
                          await Navigator.of(context).pushNamed('/p/$id');
                        }
                      },
                    ),

                  ],
                ),
              ),

            // 4. HARDWARE & HEALTH CONNECT (HealthKit / Health Connect)
            const _HealthSyncCard(),

            // 5. ACTION BUTTONS
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('CẬP NHẬT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.loss,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('ĐĂNG XUẤT'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
    return accountSwitcher == null
        ? content
        : Column(
            children: [
              accountSwitcher!,
              Expanded(child: content),
            ],
          );
  }
}

// ---------------------------------------------------------------------------
// 1. ATHLETE IDENTITY HEADER (Tích hợp ELO & Trạng thái phân hạng / Tiến trình)
// ---------------------------------------------------------------------------
class _AthleteHeaderCard extends StatelessWidget {
  const _AthleteHeaderCard({
    required this.player,
    required this.onViewPassport,
    this.onEdit,
  });
  final PlayerProfile player;
  final VoidCallback onViewPassport;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final calibrated = player.isCalibrated;
    final next = player.nextTierProgress;
    final progress = calibrated
        ? next.progress
        : player.placementMatchesCompleted / 5;
    return BentoCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: AppColors.mint,
                child: ClipOval(
                  child: player.avatarUrl != null
                      ? Image.network(
                          player.avatarUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(player.initials),
                        )
                      : Text(
                          player.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      player.homeCourtName ?? 'Hồ sơ vận động viên',
                      style: AppTokens.label,
                    ),
                  ],
                ),
              ),
              if (player.isIdentityVerified)
                const Icon(Icons.verified, color: AppColors.primary, size: 18),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Chỉnh sửa hồ sơ',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Center(
            child: SizedBox(
              width: 164,
              height: 164,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.border,
                      color: AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        player.eloRating?.toString() ?? '—',
                        style: AppTokens.metric.copyWith(
                          fontSize: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        calibrated ? player.tierName : 'Đang phân hạng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!calibrated) ...[
            Text(
              '${player.placementMatchesCompleted}/5 trận',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Điểm tạm tính · Hoàn tất phân hạng để xác định trình độ.',
              textAlign: TextAlign.center,
              style: AppTokens.label,
            ),
          ] else ...[
            Text(
              next.pointsNeeded > 0
                  ? 'Còn ${next.pointsNeeded} Elo đến ${next.nextTier}'
                  : next.nextTier,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              next.pointsNeeded > 0
                  ? 'Tiến độ trong bậc hiện tại · Mốc ${next.targetElo} Elo'
                  : 'Bạn đã đạt bậc cao nhất hiện tại',
              textAlign: TextAlign.center,
              style: AppTokens.label,
            ),
          ],
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: onViewPassport,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('MÃ QR HỘ CHIẾU THỂ THAO'),
          ),
          if (player.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tham gia ${player.memberSinceFormatted}',
              textAlign: TextAlign.center,
              style: AppTokens.label,
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceMetricsCard extends StatelessWidget {
  const _PerformanceMetricsCard({required this.player});
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Cột 1: Chuỗi thắng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: AppColors.streak,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'CHUỖI THẮNG',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.streak.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${player.winStreak}',
                    style: AppTokens.metric.copyWith(
                      fontSize: 28,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Set thắng liên tục',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            // Đường kẻ ngăn cách dọc
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.border,
            ),
            // Cột 2: Điểm uy tín
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'ĐIỂM UY TÍN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${player.trustScore}',
                    style: AppTokens.metric.copyWith(
                      fontSize: 28,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.trustStatusText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. HARDWARE & HEALTH CONNECT (Strava Health Sync Card)
// ---------------------------------------------------------------------------
class _HealthSyncCard extends StatelessWidget {
  const _HealthSyncCard();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.redAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apple Health / Health Connect',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Sẵn sàng đồng bộ nhịp tim và calo khi ra sân',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'GIAI ĐOẠN 2',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. NHẬT KÝ THI ĐẤU (Strava Athlete Diary & Deduplicated Session History)
// ---------------------------------------------------------------------------
class _MatchDiarySection extends StatefulWidget {
  const _MatchDiarySection({
    required this.activityRepository,
    this.roomRepository,
    this.refreshToken,
    required this.onProfileRefresh,
  });

  final ActivityRepository activityRepository;
  final RoomRepository? roomRepository;
  final int? refreshToken;
  final VoidCallback onProfileRefresh;

  @override
  State<_MatchDiarySection> createState() => _MatchDiarySectionState();
}

class _SessionItem {
  _SessionItem({
    required this.roomId,
    required this.primary,
    required this.hasDraft,
    required this.hasPublished,
    required this.isHostSession,
    required this.allPosts,
  });

  final String roomId;
  final ActivityView primary;
  final bool hasDraft;
  final bool hasPublished;
  final bool isHostSession;
  final List<ActivityView> allPosts;
}

class _MatchDiarySectionState extends State<_MatchDiarySection> {
  List<ActivityView> _drafts = [];
  List<ActivityView> _published = [];
  bool _loading = false;
  String? _error;

  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_MatchDiarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_generation;
    setState(() => _loading = true);
    try {
      final drafts = await widget.activityRepository.drafts();
      final published = await widget.activityRepository.list(
        mine: true,
        offset: 0,
      );
      if (mounted && gen == _generation) {
        setState(() {
          _drafts = drafts;
          _published = published;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && gen == _generation) {
        setState(() => _error = 'Không thể tải nhật ký thi đấu.');
      }
    } finally {
      if (mounted && gen == _generation) {
        setState(() => _loading = false);
      }
    }
  }


  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // DEDUPLICATION BY SESSION (roomId):
  // Nhóm các bài đăng theo roomId để đảm bảo tính theo buổi chơi,
  // tuyệt đối không cộng trùng bài cá nhân và bài host summary của cùng 1 buổi!
  Map<String, List<ActivityView>> get _sessionMap {
    final map = <String, List<ActivityView>>{};
    for (final post in [..._drafts, ..._published]) {
      map.putIfAbsent(post.roomId, () => []).add(post);
    }
    return map;
  }

  List<_SessionItem> get _allSessions {
    final list = <_SessionItem>[];
    for (final entry in _sessionMap.entries) {
      final posts = entry.value;
      final hasDraft = posts.any((p) => p.isDraft);
      final hasPublished = posts.any((p) => !p.isDraft);
      final isHostSession = posts.any(
        (p) => p.kind == ActivityKind.hostSummary,
      );
      // Ưu tiên hiển thị bài cá nhân, nếu không có thì lấy host summary
      final primary = posts.firstWhere(
        (p) => p.kind == ActivityKind.personal,
        orElse: () => posts.first,
      );
      list.add(
        _SessionItem(
          roomId: entry.key,
          primary: primary,
          hasDraft: hasDraft,
          hasPublished: hasPublished,
          isHostSession: isHostSession,
          allPosts: posts,
        ),
      );
    }
    list.sort((a, b) => b.primary.playedAt.compareTo(a.primary.playedAt));
    return list;
  }

  int get _totalSessions => _sessionMap.length;

  int get _totalWins {
    int count = 0;
    for (final s in _allSessions) {
      if (s.primary.kind == ActivityKind.personal) {
        count += s.primary.totals.wins ?? 0;
      }
    }
    return count;
  }

  int get _totalLosses {
    int count = 0;
    for (final s in _allSessions) {
      if (s.primary.kind == ActivityKind.personal) {
        count += s.primary.totals.losses ?? 0;
      }
    }
    return count;
  }

  int get _totalMatches {
    int count = 0;
    for (final s in _allSessions) {
      if (s.primary.kind == ActivityKind.personal) {
        count += s.primary.totals.total;
      }
    }
    return count;
  }

  int get _winRate {
    final total = _totalWins + _totalLosses;
    if (total == 0) return 0;
    return ((_totalWins / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allSessions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiêu đề khu vực
        Row(
          children: [
            const Icon(
              Icons.sports_tennis_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'NHẬT KÝ THI ĐẤU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _load,
              tooltip: 'Làm mới nhật ký',
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_error != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.loss.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.loss.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.loss,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.loss, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Athletic Summary Card (Tổng kết thi đấu theo session, không cộng trùng)
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG KẾT THI ĐẤU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Nhật ký các buổi chơi đã hoàn thành',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              // 4 Metrics Grid (Tính chuẩn theo session, không cộng trùng)
              Row(
                children: [
                  _buildMetricCell('Buổi chơi', '$_totalSessions'),
                  _buildMetricCell('Số trận', '$_totalMatches'),
                  _buildMetricCell('Thắng - Thua', '$_totalWins-$_totalLosses'),
                  _buildMetricCell(
                    'Tỷ lệ thắng',
                    '$_winRate%',
                    highlight: _winRate >= 50,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),


        if (_loading && _allSessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          BentoCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 36,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa có hoạt động nào trong nhật ký',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Các trận đấu và buổi giao lưu bạn đã tham gia sẽ được tự động lưu lại tại đây.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Badge trạng thái
                    Row(
                      children: [

                        if (item.isHostSession) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.streak.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '👑 Host buổi chơi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.streak,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tiêu đề & Địa điểm
                    Text(
                      item.primary.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.primary.courtName} · ${_formatTime(item.primary.playedAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),

                    if (item.primary.caption.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '“${item.primary.caption}”',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.text,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Sân đồ họa
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BadmintonCourtGraphic(
                        post: item.primary,
                        height: 85,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Thống kê trận
                    Text(
                      '${item.primary.totals.total} trận · ${item.primary.totals.wins ?? 0} thắng · ${item.primary.totals.losses ?? 0} thua',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ActivityShareSheet.show(context, item.primary),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.share_outlined, size: 14),
                            label: const Text(
                              'Lưu ảnh thành tích',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        if (widget.roomRepository != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActivityDetailPage(
                                      repository: widget.activityRepository,
                                      rooms: widget.roomRepository!,
                                      activityId: item.primary.id,
                                    ),
                                  ),
                                );
                                _load();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Xem tỉ số',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildMetricCell(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: highlight ? AppColors.primary : AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}