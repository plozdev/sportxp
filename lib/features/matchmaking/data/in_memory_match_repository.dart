import '../domain/match_repository.dart';
import '../domain/match_room.dart';

/// Demo only. Production joins must be atomic on the server.
class InMemoryMatchRepository implements MatchRepository {
  InMemoryMatchRepository() {
    _rooms.add(
      MatchRoom(
        id: 'demo-room',
        courtName: 'Sân Đào Duy Anh',
        startsAt: DateTime.now().add(const Duration(hours: 2)),
        hostId: 'minh',
        playerIds: ['minh', 'linh', 'nam'],
        distanceKm: 1.8,
      ),
    );
  }
  final List<MatchRoom> _rooms = [];
  int _sequence = 0;
  @override
  Future<List<MatchRoom>> listRooms() async => List.unmodifiable(_rooms);
  @override
  Future<MatchRoom> createRoom({
    required String courtName,
    required DateTime startsAt,
    required String hostId,
  }) async {
    if (!startsAt.isAfter(DateTime.now())) {
      throw ArgumentError('Giờ bắt đầu phải nằm trong tương lai.');
    }
    final room = MatchRoom(
      id: 'local-${++_sequence}',
      courtName: courtName.trim(),
      startsAt: startsAt,
      hostId: hostId,
      playerIds: [hostId],
    );
    _rooms.insert(0, room);
    return room;
  }

  @override
  Future<MatchRoom> joinRoom(String roomId, String playerId) async {
    final index = _rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) throw StateError('Không tìm thấy kèo.');
    if (!_rooms[index].startsAt.isAfter(DateTime.now())) {
      throw StateError('Kèo đã bắt đầu.');
    }
    return _rooms[index] = _rooms[index].join(playerId);
  }
}
