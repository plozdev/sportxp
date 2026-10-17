/// Provisional thresholds, pending product approval and server configuration.
enum RankTier {
  bronze('Đồng', 0),
  silver('Bạc', 1000),
  gold('Vàng', 1400),
  platinum('Bạch Kim', 1800);

  const RankTier(this.label, this.minimumElo);
  final String label;
  final int minimumElo;
  static RankTier fromElo(int elo) {
    if (elo < 0) throw ArgumentError.value(elo, 'elo');
    return values.lastWhere((tier) => elo >= tier.minimumElo);
  }
}
