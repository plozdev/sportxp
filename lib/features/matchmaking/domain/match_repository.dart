import 'match_room.dart';

abstract interface class MatchRepository {
  Future<List<MatchRoom>> listRooms();
  Future<MatchRoom> createRoom({
    required String courtName,
    required DateTime startsAt,
    required String hostId,
  });
  Future<MatchRoom> joinRoom(String roomId, String playerId);
}
