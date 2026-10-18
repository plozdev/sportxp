import '../../matchmaking/domain/court.dart';
import 'managed_room.dart';
import 'room_search.dart';

/// Read projections + immutable commands: adapters own storage and validation.
abstract interface class RoomRepository {
  Future<List<ManagedRoom>> list(
    String scope, {
    int offset = 0,
    RoomSearch? search,
  });
  Future<ManagedRoom?> get(String id);
  Future<String> execute(RoomCommand command);
  Future<List<Court>> courts();
  Future<List<Map<String, dynamic>>> notices();
  Future<void> readNotices(int through);
}

/// Future backend adapter can implement this without changing session screens.
abstract interface class RoomSessionRepository implements RoomRepository {
  Future<Map<String, dynamic>> session(String roomId);
}
