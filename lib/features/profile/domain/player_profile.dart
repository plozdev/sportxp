class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.displayName,
    required this.eloRating,
    required this.tierName,
    required this.trustScore,
    required this.winStreak,
  });
  final String id, displayName, tierName;
  final int? eloRating;
  final int trustScore, winStreak;
  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String? ?? 'Vận động viên',
    eloRating: (json['elo_rating'] as num?)?.toInt(),
    tierName: json['tier_name'] as String? ?? 'Chưa xếp hạng',
    trustScore: (json['trust_score'] as num).toInt(),
    winStreak: (json['win_streak'] as num).toInt(),
  );
}
