class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.eloRating,
    required this.tierName,
    required this.trustScore,
    required this.winStreak,
    this.homeCourtId,
    this.homeCourtName,
    this.createdAt,
    this.onboardingStep = 0,
  });

  final String id, displayName, tierName;
  final String? avatarUrl;
  final int? eloRating;
  final int trustScore, winStreak;
  final String? homeCourtId;
  final String? homeCourtName;
  final DateTime? createdAt;
  final int onboardingStep;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final court = json['courts'] as Map<String, dynamic>?;
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'] as String)?.toLocal();
    }
    return PlayerProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Vận động viên',
      avatarUrl: json['avatar_url'] as String?,
      eloRating: (json['elo_rating'] as num?)?.toInt(),
      tierName: json['tier_name'] as String? ?? 'Chưa xếp hạng',
      trustScore: (json['trust_score'] as num?)?.toInt() ?? 100,
      winStreak: (json['win_streak'] as num?)?.toInt() ?? 0,
      homeCourtId: json['home_court_id']?.toString(),
      homeCourtName: court?['name'] as String?,
      createdAt: parsedDate,
      onboardingStep: (json['onboarding_step'] as num?)?.toInt() ?? 0,
    );
  }

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'XP';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String get memberSinceFormatted {
    if (createdAt == null) return 'Mới gia nhập';
    return 'Tháng ${createdAt!.month}, ${createdAt!.year}';
  }

  /// Thông tin mốc Elo tiếp theo
  ({String nextTier, int targetElo, int pointsNeeded, double progress}) get nextTierProgress {
    final elo = eloRating ?? 300;
    if (elo < 450) {
      const min = 300, max = 450;
      final progress = ((elo - min) / (max - min)).clamp(0.0, 1.0);
      return (nextTier: 'Phong trào cơ bản', targetElo: max, pointsNeeded: max - elo, progress: progress);
    }
    if (elo < 600) {
      const min = 450, max = 600;
      final progress = ((elo - min) / (max - min)).clamp(0.0, 1.0);
      return (nextTier: 'Phong trào Trung bình', targetElo: max, pointsNeeded: max - elo, progress: progress);
    }
    if (elo < 750) {
      const min = 600, max = 750;
      final progress = ((elo - min) / (max - min)).clamp(0.0, 1.0);
      return (nextTier: 'Phong trào Khá', targetElo: max, pointsNeeded: max - elo, progress: progress);
    }
    if (elo < 1000) {
      const min = 750, max = 1000;
      final progress = ((elo - min) / (max - min)).clamp(0.0, 1.0);
      return (nextTier: 'Bán chuyên / Thi đấu', targetElo: max, pointsNeeded: max - elo, progress: progress);
    }
    return (nextTier: 'Đỉnh cao bảng đấu', targetElo: elo, pointsNeeded: 0, progress: 1.0);
  }

  String get trustStatusText {
    if (trustScore >= 95) return 'Uy tín tuyệt đối';
    if (trustScore >= 80) return 'Đáng tin cậy';
    if (trustScore >= 60) return 'Cần cải thiện';
    return 'Cảnh báo bùng kèo';
  }
}
