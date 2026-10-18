import 'package:supabase_flutter/supabase_flutter.dart';

import '../../matchmaking/domain/court.dart';
import '../domain/managed_room.dart';
import '../domain/room_repository.dart';
import '../domain/room_search.dart';

class ManagedRoomRepository implements RoomRepository {
  ManagedRoomRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<ManagedRoom>> list(
    String scope, {
    int offset = 0,
    RoomSearch? search,
  }) async {
    if (search != null) {
      throw const RoomRuleException(
        'Bộ lọc Phase 3 hiện chỉ hỗ trợ trong mock.',
      );
    }
    final rows = await client.rpc(
      'list_rooms_v2',
      params: {'p_scope': scope, 'p_offset': offset},
    );
    return (rows as List)
        .map((r) => ManagedRoom.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<ManagedRoom?> get(String id) async {
    final row = await client.rpc('get_room_v2', params: {'p_room_id': id});
    return row == null
        ? null
        : ManagedRoom.fromJson(Map<String, dynamic>.from(row as Map));
  }

  @override
  Future<String> execute(RoomCommand command) async {
    final session = client.auth.currentSession;
    if (session == null || session.isExpired) {
      throw const AuthException('Vui lòng đăng nhập lại.');
    }
    return await client.rpc(
      'room_command_v2',
      params: {
        'p_request_id': command.requestId,
        'p_action': command.action,
        'p_room_id': command.roomId,
        'p_payload': command.payload,
      },
    ) as String;
  }

  @override
  Future<List<Court>> courts() async {
    final rows = await client
        .from('courts')
        .select('id, name, distance_km')
        .order('name');
    return rows.map(Court.fromJson).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> notices() async {
    final rows = await client.rpc('room_notices_v2');
    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  @override
  Future<void> readNotices(int through) async {
    await client.rpc('read_room_notices_v2', params: {'p_through_id': through});
  }
}

String roomFailure(Object error) {
  if (error is RoomRuleException) return error.message;
  final message = error is PostgrestException
      ? error.message
      : error.toString();
  const labels = {
    'SCHEDULE_CONFLICT': 'Bạn đã có lịch trùng với buổi này.',
    'HOST_SKILL_OUT_OF_RANGE':
        'Trình của host đang nằm ngoài khoảng Elo đã chọn.',
    'NOT_ELIGIBLE': 'Không đủ điều kiện trình độ hoặc quyền vào phòng.',
    'ROOM_FULL': 'Phòng vừa đủ người. Bạn có thể vào danh sách chờ.',
    'ROOM_UNAVAILABLE': 'Phòng không tồn tại hoặc bạn không có quyền xem.',
    'REVISION_CONFLICT': 'Điều kiện phòng đã đổi. Tải lại trước khi xác nhận.',
    'CAPACITY_BELOW_MEMBERS': 'Số chỗ mới thấp hơn số chỗ đã giữ.',
    'REGISTRATION_CLOSED': 'Phòng đã đóng đăng ký hoặc đã đến giờ chơi.',
    'NOT_ENOUGH_PLAYERS': 'Cần ít nhất hai người chơi đã xác nhận để bắt đầu.',
    'ANOTHER_SESSION_ACTIVE':
        'Host hoặc người chơi vẫn đang ở một buổi chưa kết thúc.',
    'OUTSIDE_START_WINDOW': 'Chỉ bắt đầu trong khoảng giờ đã công bố.',
    'RECONFIRMATION_REQUIRED':
        'Còn người chưa xác nhận lại lịch. Cần xử lý trước khi bắt đầu.',
    'HOST_ONLY': 'Chỉ host được thực hiện thao tác này.',
    'HOST_MUST_CANCEL_ROOM': 'Host cần hủy buổi thay vì rời phòng.',
    'ROOM_LOCKED': 'Không thể thực hiện ở trạng thái hiện tại.',
    'INVALID_ROOM_TERMS': 'Kiểm tra lại thời gian, sân, số chỗ, Elo và phí.',
    'IDEMPOTENCY_CONFLICT':
        'Yêu cầu cũ đã được dùng. Tải lại danh sách để kiểm tra kết quả.',
    'REASON_REQUIRED': 'Vui lòng nhập lý do hủy buổi.',
  };
  for (final entry in labels.entries) {
    if (message.contains(entry.key)) return entry.value;
  }
  if (error is PostgrestException &&
      ['PGRST202', '42883'].contains(error.code)) {
    return 'Backend chưa có Phase 2A. Cần áp dụng migration rooms trước khi bật tính năng.';
  }
  return 'Chưa xác nhận được kết quả. Tải lại để kiểm tra; gửi lại cùng yêu cầu sẽ không tạo trùng.';
}

class RoomRuleException implements Exception {
  const RoomRuleException(this.message);
  final String message;
}
