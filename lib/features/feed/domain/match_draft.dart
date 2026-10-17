class MatchDraft {
  const MatchDraft({
    required this.courtName,
    required this.teamA,
    required this.teamB,
    required this.score,
    required this.isWin,
  });
  final String courtName, teamA, teamB, score;
  final bool isWin;

  static String? validateScore(String? value) {
    final score = (value ?? '').trim();
    if (!RegExp(
      r'^\d{1,2}\s*[-–]\s*\d{1,2}(?:\s+\d{1,2}\s*[-–]\s*\d{1,2}){0,2}$',
    ).hasMatch(score)) {
      return 'Nhập 1–3 set, ví dụ: 21-19 21-16.';
    }
    final sets = RegExp(r'(\d+)\s*[-–]\s*(\d+)').allMatches(score);
    for (final set in sets) {
      final a = int.parse(set[1]!);
      final b = int.parse(set[2]!);
      final high = a > b ? a : b;
      final low = a > b ? b : a;
      if (high > 30 ||
          high < 21 ||
          (high == 21 && low > 19) ||
          (high > 21 && high < 30 && high - low != 2) ||
          (high == 30 && low != 28 && low != 29)) {
        return 'Tỉ số set phải kết thúc ở 21 điểm, cách 2 điểm hoặc chạm 30.';
      }
    }
    return null;
  }
}
