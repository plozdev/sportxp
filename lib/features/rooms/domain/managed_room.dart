import 'dart:math';

String newRoomRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Keep this immutable command across retries after an uncertain network result.
class RoomCommand {
  RoomCommand(
    this.action, {
    this.roomId,
    Map<String, dynamic> payload = const {},
    String? requestId,
  }) : payload = Map<String, dynamic>.unmodifiable(
         payload.map((key, value) => MapEntry(key, _freeze(value))),
       ),
       requestId = requestId ?? newRoomRequestId();
  final String action, requestId;
  final String? roomId;
  final Map<String, dynamic> payload;

  static dynamic _freeze(dynamic value) => switch (value) {
    Map v => Map.unmodifiable(
      v.map((key, item) => MapEntry(key, _freeze(item))),
    ),
    List v => List.unmodifiable(v.map(_freeze)),
    _ => value,
  };
}

class ManagedRoom {
  ManagedRoom.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      courtId = json['court_id'] as String,
      title = json['title'] as String,
      courtName = json['court_name'] as String,
      address = json['court_address'] as String? ?? '',
      startsAt = DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt = DateTime.parse(json['ends_at'] as String).toLocal(),
      cancelBy = DateTime.parse(json['cancel_by'] as String).toLocal(),
      capacity = (json['capacity'] as num).toInt(),
      reserved = (json['reserved'] as num).toInt(),
      minElo = (json['min_elo'] as num).toInt(),
      maxElo = (json['max_elo'] as num).toInt(),
      fee = (json['fee'] as num).toInt(),
      revision = (json['revision'] as num).toInt(),
      visibility = json['visibility'] as String,
      status = json['status'] as String,
      hostPlays = json['host_plays'] as bool,
      isHost = json['is_host'] as bool,
      hostName = json['host_name'] as String,
      myStatus = json['my_status'] as String?,
      cancellationReason = json['cancellation_reason'] as String?,
      notes = json['notes'] as String? ?? '',
      courtLabel = json['court_label'] as String? ?? '',
      bookingStatus = json['booking_status'] as String? ?? 'UNCONFIRMED',
      viewerId = json['viewer_id'] as String?,
      members = List<Map<String, dynamic>>.unmodifiable(
        (json['members'] as List? ?? []).map(
          (row) => Map<String, dynamic>.unmodifiable(row as Map),
        ),
      );
  final String id,
      courtId,
      title,
      courtName,
      address,
      visibility,
      status,
      hostName,
      notes,
      courtLabel;
  final String bookingStatus;
  final String? viewerId;
  final String? myStatus;
  final String? cancellationReason;
  final DateTime startsAt, endsAt, cancelBy;
  final int capacity, reserved, minElo, maxElo, fee, revision;
  final bool hostPlays, isHost;
  final List<Map<String, dynamic>> members;
  bool get canRegister =>
      ['OPEN', 'FULL'].contains(status) && startsAt.isAfter(DateTime.now());
  bool get canEdit => isHost && ['DRAFT', 'OPEN', 'FULL'].contains(status);
  String get statusLabel => switch (status) {
    'DRAFT' => 'Nháp',
    'OPEN' => 'Đang tuyển',
    'FULL' => 'Đủ người',
    'IN_PROGRESS' => 'Đang diễn ra',
    'COMPLETED' => 'Đã kết thúc',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };
  Map<String, dynamic> get editableTerms => {
    'court_id': courtId,
    'title': title,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'cancel_by': cancelBy.toUtc().toIso8601String(),
    'capacity': capacity,
    'min_elo': minElo,
    'max_elo': maxElo,
    'fee': fee,
    'visibility': visibility,
    'host_plays': hostPlays,
    'notes': notes,
    'court_label': courtLabel,
    'draft': status == 'DRAFT',
    'expected_revision': revision,
  };
}
