import 'package:flutter/foundation.dart';
import '../domain/match_repository.dart';
import '../domain/match_room.dart';

class MatchController extends ChangeNotifier {
  MatchController(this._repository);
  final MatchRepository _repository;
  static const currentPlayerId = 'demo-player';
  List<MatchRoom> _rooms = [];
  List<MatchRoom> get rooms => List.unmodifiable(_rooms);
  bool busy = false;
  String? error;
  bool _disposed = false;
  Future<bool> _run(Future<void> Function() operation) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await operation();
      _rooms = await _repository.listRooms();
      return true;
    } catch (_) {
      error = 'Không thể cập nhật kèo. Vui lòng thử lại.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> load() => _run(() async {});
  Future<bool> join(String id) => _run(() async {
    await _repository.joinRoom(id, currentPlayerId);
  });
  Future<bool> create(String court, DateTime startsAt) => _run(() async {
    await _repository.createRoom(
      courtName: court,
      startsAt: startsAt,
      hostId: currentPlayerId,
    );
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
