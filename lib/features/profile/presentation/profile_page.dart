import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../../feed/domain/match_summary.dart';
import '../data/profile_repository.dart';
import '../domain/player_profile.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/passport_sheet.dart';
import '../../social/data/social_repository.dart';
import '../../social/presentation/connections_page.dart';
import '../../social/presentation/scan_profile_page.dart';
import '../../auth/presentation/auth_page.dart';

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
  final dynamic activityRepository;
  final dynamic roomRepository;
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

            // 3. LỊCH SỬ THI ĐẤU (Truy vấn match_results từ database)
            if (repository != null)
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: const Text('Lịch sử thi đấu'),
                subtitle: const Text(
                  'Các trận đấu và kết quả đối đầu đã ghi nhận',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Lịch sử thi đấu')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: _RecentMatchesSection(
                          repository: repository!,
                          player: player,
                          refreshToken: refreshToken,
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
// 4. LỊCH SỬ THI ĐẤU GẦN ĐÂY (Truy vấn trực tiếp match_results từ Supabase)
// ---------------------------------------------------------------------------
class _RecentMatchesSection extends StatefulWidget {
  const _RecentMatchesSection({
    required this.repository,
    required this.player,
    this.refreshToken,
  });

  final ProfileRepository repository;
  final PlayerProfile player;
  final int? refreshToken;

  @override
  State<_RecentMatchesSection> createState() => _RecentMatchesSectionState();
}

class _RecentMatchesSectionState extends State<_RecentMatchesSection> {
  late Future<List<MatchSummary>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_RecentMatchesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  void _load() {
    _matchesFuture =
        widget.repository.playerRecentMatches(widget.player.displayName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MatchSummary>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return const BentoCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  Icon(Icons.sports_tennis, size: 36, color: AppColors.muted),
                  SizedBox(height: 10),
                  Text(
                    'Chưa có kết quả trận đấu nào được ghi nhận',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kết quả thi đấu tại các buổi chơi sẽ hiển thị tại đây.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: matches.map((m) => _MatchSummaryCard(match: m)).toList(),
        );
      },
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  const _MatchSummaryCard({required this.match});
  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    final isWin = match.isWin;
    final elo = match.eloChange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isWin ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isWin ? AppColors.primary : AppColors.loss,
                ),
                const SizedBox(width: 6),
                Text(
                  isWin ? 'THẮNG' : 'THUA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isWin ? AppColors.primary : AppColors.loss,
                  ),
                ),
                const Spacer(),
                if (elo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isWin
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.loss.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ' Elo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isWin ? AppColors.primary : AppColors.loss,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.teamA,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isWin ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.teamB,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              !isWin ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.score,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    match.courtName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '//',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
