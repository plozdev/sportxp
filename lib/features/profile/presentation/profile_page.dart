import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_panel.dart';
import '../../../shared/widgets/bento_card.dart';
import '../data/profile_repository.dart';
import '../domain/player_profile.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/passport_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.profile,
    required this.isSignedIn,
    required this.onSignIn,
    required this.onSignOut,
    required this.onRefresh,
    this.repository,
  });

  final Future<PlayerProfile?> profile;
  final bool isSignedIn;
  final VoidCallback onSignIn, onSignOut, onRefresh;
  final ProfileRepository? repository;

  void _openPassport(BuildContext context, PlayerProfile player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PassportSheet(profile: player),
    );
  }

  Future<void> _openEditProfile(BuildContext context, PlayerProfile player) async {
    if (repository == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        profile: player,
        loadCourts: repository!.loadCourts,
        onSave: (name, courtId) => repository!.updateProfile(
          displayName: name,
          homeCourtId: courtId,
        ),
      ),
    );
    if (updated == true) onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSignedIn) {
      return PageContent(
        children: [
          _buildSignedOutHero(context),
        ],
      );
    }

    return AsyncPanel<PlayerProfile?>(
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chưa tìm thấy hồ sơ cho tài khoản này. Vui lòng thử cập nhật lại hoặc kiểm tra kết nối mạng.',
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
              OutlinedButton(onPressed: onSignOut, child: const Text('ĐĂNG XUẤT')),
            ],
          );
        }

        return PageContent(
          children: [
            // 1. ATHLETE IDENTITY HEADER (Strava inspired)
            _AthleteHeaderCard(
              player: player,
              onViewPassport: () => _openPassport(context, player),
              onEdit: repository != null ? () => _openEditProfile(context, player) : null,
            ),

            // 2. PLACEMENT MATCHES TRACKER (5 trận định hạng & K-Factor)
            _PlacementTrackerCard(player: player),

            // 3. CORE ELO & TIER CARD
            _EloProgressCard(player: player),

            // 4. ATHLETIC METRICS (Streak, Trust Score, Home Court)
            _AthleticMetricsBento(player: player),

            // 5. HARDWARE & HEALTH CONNECT (HealthKit / Health Connect)
            const _HealthSyncCard(),

            // 6. ACTION BUTTONS
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
  }

  Widget _buildSignedOutHero(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sports_tennis, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HỘ CHIẾU THỂ THAO SỐ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'SPORTXP PROFILE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mọi set cầu đều được định danh và ghi nhận. Đăng nhập để kích hoạt hệ số Elo, tích lũy điểm uy tín và nhận thẻ Hộ chiếu thể thao cá nhân.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSignIn,
            icon: const Icon(Icons.login),
            label: const Text('ĐĂNG NHẬP HOẶC TẠO TÀI KHOẢN'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. ATHLETE IDENTITY HEADER
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
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Athlete Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 76,
                    height: 76,
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
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name & Metadata
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
                    // Tier Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        player.tierName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          player.memberSinceFormatted,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.muted),
                  tooltip: 'Chỉnh sửa hồ sơ',
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Home Court Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.homeCourtName != null
                        ? 'Sân nhà: ${player.homeCourtName}'
                        : 'Chưa gắn sân nhà • Bấm chỉnh sửa để chọn sân quen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: player.homeCourtName != null ? FontWeight.w600 : FontWeight.normal,
                      color: player.homeCourtName != null ? AppColors.text : AppColors.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Primary Action: View 9:16 Digital Passport
          FilledButton.icon(
            onPressed: onViewPassport,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.primary),
            ),
            icon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 18),
            label: const Text('XEM HỘ CHIẾU CẦU LÔNG (9:16 SHARE)'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. PLACEMENT TRACKER CARD (5 trận định hạng)
// ---------------------------------------------------------------------------
class _PlacementTrackerCard extends StatelessWidget {
  const _PlacementTrackerCard({required this.player});
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    // 5 trận định hạng: nếu onboarding hoàn tất và chưa qua 5 trận
    final isCalibrated = player.winStreak > 5; // hoặc đã hoàn thành giai đoạn placement
    const totalPlacement = 5;
    final completed = (player.winStreak).clamp(0, totalPlacement);

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.radar, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'ĐỊNH HẠNG BAN ĐẦU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCalibrated ? AppColors.primary.withValues(alpha: 0.15) : AppColors.streak.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isCalibrated ? 'ĐÃ XÁC THỰC' : 'TẠM TÍNH ($completed/5 TRẬN)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCalibrated ? AppColors.primary : AppColors.streak,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 5 indicator dots
          Row(
            children: List.generate(totalPlacement, (index) {
              final isDone = index < completed || isCalibrated;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(right: index < totalPlacement - 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text(
            'Hệ số K = 64 được kích hoạt trong 5 trận đầu tiên giúp điểm số tăng/giảm nhanh, nhanh chóng tiệm cận thực lực thật và triệt tiêu Smurf.',
            style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. ELO & TIER CARD
// ---------------------------------------------------------------------------
class _EloProgressCard extends StatelessWidget {
  const _EloProgressCard({required this.player});
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final nextInfo = player.nextTierProgress;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'CHỈ SỐ ELO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.muted,
                ),
              ),
              Text(
                'Hạng: ${player.tierName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                player.eloRating?.toString() ?? '—',
                style: AppTokens.metric.copyWith(fontSize: 40, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Điểm\nKỹ năng',
                style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress to next tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mục tiêu: ${nextInfo.nextTier}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                nextInfo.pointsNeeded > 0 ? 'Còn +${nextInfo.pointsNeeded} Elo' : 'Hạng cao nhất',
                style: TextStyle(
                  fontSize: 11,
                  color: nextInfo.pointsNeeded > 0 ? AppColors.primary : AppColors.streak,
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
              backgroundColor: AppColors.background,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. ATHLETIC METRICS (Streak & Trust Score)
// ---------------------------------------------------------------------------
class _AthleticMetricsBento extends StatelessWidget {
  const _AthleticMetricsBento({required this.player});
  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Win Streak Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, size: 18, color: AppColors.streak),
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
                const SizedBox(height: 10),
                Text(
                  '${player.winStreak}',
                  style: AppTokens.metric.copyWith(fontSize: 26, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set thắng liên tục',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Trust Score Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
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
                const SizedBox(height: 10),
                Text(
                  '${player.trustScore}',
                  style: AppTokens.metric.copyWith(fontSize: 26, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  player.trustStatusText,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. HARDWARE & HEALTH CONNECT (Strava Health Sync Card)
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
            child: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
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
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
