class CreateRoomDraft {
  const CreateRoomDraft({
    required this.courtId,
    required this.startsAt,
    required this.maxSlots,
  });
  final String courtId;
  final DateTime startsAt;
  final int maxSlots;
}
