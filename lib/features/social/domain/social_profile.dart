class SocialProfile {
  const SocialProfile({
    required this.publicId,
    required this.name,
    required this.relationship,
    this.elo,
    this.tier,
    this.streak = 0,
    this.statsVisible = true,
  });
  final String publicId, name, relationship;
  final int? elo;
  final String? tier;
  final int streak;
  final bool statsVisible;
  factory SocialProfile.fromJson(Map<String, dynamic> json) => SocialProfile(
    publicId: json['public_id'] as String,
    name: json['display_name'] as String,
    relationship: json['relationship'] as String,
    elo: (json['elo_rating'] as num?)?.toInt(),
    tier: json['tier_name'] as String?,
    streak: (json['win_streak'] as num?)?.toInt() ?? 0,
    statsVisible: json.containsKey('elo_rating'),
  );
}
