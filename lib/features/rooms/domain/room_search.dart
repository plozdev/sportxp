/// Query values cross the repository boundary. Filter before pagination.
/// Distance is a fixed fixture value until a backend location policy is chosen.
class RoomSearch {
  const RoomSearch({
    this.area,
    this.maxDistanceKm,
    this.date,
    this.skill,
    this.maxFee,
    this.availableOnly = false,
  });
  final String? area;
  final double? maxDistanceKm;
  final DateTime? date;
  final int? skill, maxFee;
  final bool availableOnly;
}
