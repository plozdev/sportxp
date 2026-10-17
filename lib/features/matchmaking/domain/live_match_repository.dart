import '../../feed/domain/match_draft.dart';
import '../../feed/domain/match_summary.dart';
import 'court.dart';
import 'create_room_draft.dart';
import 'match_room.dart';

/// Backend boundary for the live match loop. Its Supabase implementation must
/// use the existing table definitions and RPC signature, not assumed columns.
abstract interface class LiveMatchRepository {
  Future<List<MatchSummary>> feed();
  Future<List<MatchRoom>> openRooms();
  Future<List<Court>> courts();
  Future<void> createRoom(CreateRoomDraft draft);
  Future<void> joinRoom(String roomId);
  Future<void> recordMatch(MatchDraft draft);
}
