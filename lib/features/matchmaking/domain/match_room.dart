class MatchRoom {
  MatchRoom({
    required this.id,
    required this.courtName,
    required this.startsAt,
    required this.hostId,
    required List<String> playerIds,
    this.capacity = 4,
    this.distanceKm,
  }) : playerIds = List.unmodifiable(playerIds) {
    if (courtName.trim().isEmpty ||
        capacity < 2 ||
        playerIds.length > capacity ||
        !playerIds.contains(hostId) ||
        playerIds.toSet().length != playerIds.length ||
        (distanceKm != null && distanceKm! < 0)) {
      throw ArgumentError('Phòng đấu không hợp lệ.');
    }
  }
  final String id, courtName, hostId;
  final DateTime startsAt;
  final List<String> playerIds;
  final int capacity;
  // Public data never contains player coordinates.
  final double? distanceKm;
  int get availableSlots => capacity - playerIds.length;
  MatchRoom join(String playerId) {
    if (playerIds.contains(playerId)) return this;
    if (availableSlots == 0) throw StateError('Kèo đã đủ người.');
    return MatchRoom(
      id: id,
      courtName: courtName,
      startsAt: startsAt,
      hostId: hostId,
      playerIds: [...playerIds, playerId],
      capacity: capacity,
      distanceKm: distanceKm,
    );
  }
}
