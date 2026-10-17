class MatchSummary {
  const MatchSummary({
    required this.id,
    required this.courtName,
    required this.teamA,
    required this.teamB,
    required this.score,
    required this.isWin,
    required this.createdAt,
    this.eloChange,
  });
  final String id, courtName, teamA, teamB, score;
  final bool isWin;
  final DateTime createdAt;
  final int? eloChange;
}
