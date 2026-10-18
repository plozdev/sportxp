import '../../rooms/domain/managed_room.dart';

enum ActivityAudience { friends, onlyMe }

enum ActivityKind { personal, hostSummary }

/// Sanitized log boundary: no attendance, dispute reasons or private audit.
class ActivityMatchLog {
  ActivityMatchLog({
    required this.id,
    required List<String> teamA,
    required List<String> teamB,
    required this.status,
    required this.winner,
    required this.score,
    required this.version,
  }) : teamA = List.unmodifiable(teamA),
       teamB = List.unmodifiable(teamB);
  final String id, status, winner, score;
  final int version;
  final List<String> teamA, teamB;
  bool involves(String id) => teamA.contains(id) || teamB.contains(id);
}

class ActivityLog {
  ActivityLog({
    required this.roomId,
    required this.hostId,
    required this.title,
    required this.courtName,
    required this.isPrivate,
    required this.endedAt,
    required List<String> players,
    required List<ActivityMatchLog> matches,
  }) : players = List.unmodifiable(players),
       matches = List.unmodifiable(matches);
  final String roomId, hostId, title, courtName;
  final bool isPrivate;
  final DateTime endedAt;
  final List<String> players;
  final List<ActivityMatchLog> matches;
  bool participant(String id) => hostId == id || players.contains(id);
}

/// Mock implementation shares the room store. A backend should enforce these
/// permissions before returning any projection, rather than trust client checks.
abstract interface class ActivityLogSource {
  String get actorId;
  int get generation;
  Map<String, String> get actorNames;
  bool areFriends(String a, String b);
  bool isBlocked(String a, String b);
  List<ActivityLog> activityLogs();
}

class ActivityTotals {
  const ActivityTotals({
    required this.confirmed,
    required this.pending,
    required this.disputed,
    required this.voided,
    this.wins,
    this.losses,
  });
  final int confirmed, pending, disputed, voided;
  final int? wins, losses;
  int get total => confirmed + pending + disputed;
}

class ActivityView {
  const ActivityView({
    required this.id,
    required this.roomId,
    required this.authorId,
    required this.authorName,
    required this.caption,
    required this.title,
    required this.courtName,
    required this.kind,
    required this.audience,
    required this.publishedAt,
    required this.playedAt,
    required this.version,
    required this.totals,
    required this.resultsUpdated,
    required this.isOwner,
    required this.canOpenLog,
    required this.liked,
    required this.likeCount,
  });
  final String id, roomId, authorId, authorName, caption, title, courtName;
  final ActivityKind kind;
  final ActivityAudience audience;
  final DateTime? publishedAt;
  final DateTime playedAt;
  final int version, likeCount;
  final ActivityTotals totals;
  final bool resultsUpdated, isOwner, canOpenLog, liked;
  bool get isDraft => publishedAt == null;
}

class ActivityCommand {
  ActivityCommand(
    this.action, {
    required this.activityId,
    this.expectedVersion,
    this.caption,
    this.audience,
    this.liked,
    String? requestId,
  }) : requestId = requestId ?? newRoomRequestId();
  final String action, activityId, requestId;
  final int? expectedVersion;
  final String? caption;
  final ActivityAudience? audience;
  final bool? liked;
}

abstract interface class ActivityRepository {
  Future<List<ActivityView>> list({bool mine = false, int offset = 0});
  Future<List<ActivityView>> drafts();
  Future<ActivityView?> get(String id);
  Future<void> execute(ActivityCommand command);
}
