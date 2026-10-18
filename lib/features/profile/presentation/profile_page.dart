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

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.isSignedIn,
    required this.onSignOut,
    required this.onRefresh,
    this.repository,
    this.accountSwitcher,
  });

  final Future<PlayerProfile?> profile;
  final bool isSignedIn;
  final VoidCallback onSignOut, onRefresh;
  final ProfileRepository? repository;
  final Widget? accountSwitcher;

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

            // 3. KẾT NỐI & QUYỀN RIÊNG TƯ
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
                    SwitchListTile(
                      title: const Text('Hồ sơ chỉ dành cho bạn bè'),
                      subtitle: const Text(
                        'Người lạ chỉ thấy thông tin kết nối tối thiểu.',
                      ),
                      value: player.socialVisibility == 'friends',
                      onChanged: (value) async {
                        try {
                          await SocialRepository(repository!.client)
                              .visibility(value ? 'friends' : 'public');
                          onRefresh();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chưa thể cập nhật quyền riêng tư.',
                                ),
                              ),
                            );
                          }
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
    final isCalibrated = player.isCalibrated;
    final completed = player.placementMatchesCompleted;
    final nextInfo = player.nextTierProgress;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row danh tính vận động viên (Avatar, Tên, Ngày gia nhập, Sân nhà, Sửa)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar tròn viền nổi bật
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                      border: Border.all(color: AppColors.primary, width: 2),
                      image: player.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(player.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: player.avatarUrl == null
                        ? Center(
                            child: Text(
                              player.initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Tên & Ngày tham gia & Sân nhà
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tham gia ${player.memberSinceFormatted}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    if (player.homeCourtName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              player.homeCourtName!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
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
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  tooltip: 'Chỉnh sửa hồ sơ',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Khung tích hợp ELO & Trạng thái phân hạng / Tiến trình
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Điểm số ELO & Huy hiệu cấp bậc hoặc Đang phân hạng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHỈ SỐ ELO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              player.eloRating?.toString() ?? '—',
                              style: AppTokens.metric.copyWith(
                                fontSize: 34,
                                color: isCalibrated
                                    ? AppColors.primary
                                    : AppColors.streak,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCalibrated ? 'Điểm kỹ năng' : 'Điểm tạm tính',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Huy hiệu cấp bậc hoặc trạng thái phân hạng
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isCalibrated
                                    ? AppColors.primary
                                    : AppColors.streak)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              (isCalibrated
                                      ? AppColors.primary
                                      : AppColors.streak)
                                  .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCalibrated
                                ? Icons.workspace_premium
                                : Icons.hourglass_top_rounded,
                            size: 18,
                            color: isCalibrated
                                ? AppColors.primary
                                : AppColors.streak,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCalibrated ? player.tierName : 'Đang phân hạng',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isCalibrated
                                  ? AppColors.primary
                                  : AppColors.streak,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hàng 2: Logic điều kiện
                // Nếu ĐANG PHÂN HẠNG: Hiện tiến độ 5 trận phân hạng, KHÔNG hiện thanh progress mục tiêu
                // Nếu ĐÃ QUA PHÂN HẠNG: Hiện mục tiêu thăng hạng & thanh progress
                if (!isCalibrated) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ phân hạng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.streak.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$completed/5 trận',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.streak,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 5 vạch tiến độ phân hạng
                  Row(
                    children: List.generate(5, (index) {
                      final isDone = index < completed;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.streak
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isDone
                                  ? AppColors.streak
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completed == 0
                        ? 'Đấu 5 trận đầu để hệ thống xác định thứ hạng và điểm Elo chuẩn xác hơn.'
                        : 'Còn ${5 - completed} trận nữa để hoàn tất phân hạng và mở khóa mục tiêu thăng hạng.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ] else ...[
                  // Thanh tiến trình lên hạng tiếp theo khi đã hoàn tất phân hạng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mục tiêu: ${nextInfo.nextTier}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        nextInfo.pointsNeeded > 0
                            ? 'Còn +${nextInfo.pointsNeeded} Elo'
                            : 'Hạng cao nhất',
                        style: TextStyle(
                          fontSize: 11,
                          color: nextInfo.pointsNeeded > 0
                              ? AppColors.primary
                              : AppColors.streak,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: nextInfo.progress,
                      backgroundColor: AppColors.surface,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nút xem Hộ chiếu QR
          FilledButton.icon(
            onPressed: onViewPassport,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(
              Icons.qr_code_2,
              color: AppColors.primary,
              size: 20,
            ),
            label: const Text('MÃ QR HỘ CHIẾU THỂ THAO'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. CHỈ SỐ PHONG ĐỘ & UY TÍN (Chuỗi thắng & Điểm uy tín gộp trong 1 Bento Card)
// ---------------------------------------------------------------------------
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
                      Text(
                        'CHUỖI THẮNG',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.streak.withValues(alpha: 0.9),
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
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      Text(
                        'ĐIỂM UY TÍN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
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
