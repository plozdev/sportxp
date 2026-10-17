/// SportXP's Vietnam recreational badminton scale.
enum RankTier {
  newbie('Nhập môn', 300),
  lowerCasual('Phong trào cơ bản', 450),
  midCasual('Phong trào Trung bình', 600),
  upperCasual('Phong trào Khá', 750),
  advanced('Bán chuyên / Thi đấu', 1000);

  const RankTier(this.label, this.minimumElo);
  final String label;
  final int minimumElo;
  static RankTier fromElo(int elo) {
    if (elo < 0) throw ArgumentError.value(elo, 'elo');
    return values.lastWhere(
      (tier) => elo >= tier.minimumElo,
      orElse: () => newbie,
    );
  }
}
