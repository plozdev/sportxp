import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/sport_notice.dart';

abstract class NoticeRepository {
  Future<List<SportNotice>> listNotices();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class SupabaseNoticeRepository implements NoticeRepository {
  SupabaseNoticeRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<SportNotice>> listNotices() async {
    final user = client.auth.currentUser;
    if (user == null) return _fallbackNotices;

    try {
      final rows = await client.rpc('room_notices_v2');
      if (rows is List && rows.isNotEmpty) {
        return rows
            .map((r) => SportNotice.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
    } catch (_) {}

    return _fallbackNotices;
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      final numId = int.tryParse(id);
      if (numId != null) {
        await client.rpc('read_room_notices_v2', params: {'p_through_id': numId});
      }
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await client.rpc('read_room_notices_v2', params: {'p_through_id': 999999999});
    } catch (_) {}
  }

  static final List<SportNotice> _fallbackNotices = [
    SportNotice(
      id: '1',
      title: 'Chào mừng đến với SportXP!',
      content: 'Bắt đầu tìm kiếm đối thủ gần bạn hoặc đăng ký các giải đấu phong trào cuối tuần này.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      kind: 'WELCOME',
    ),
    SportNotice(
      id: '2',
      title: 'Giải đấu mới: SportXP Championship',
      content: 'Giải đấu tại Sân Cầu Lông Kỳ Hòa đang mở đăng ký. Đừng bỏ lỡ cúp vô địch!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      kind: 'TOURNAMENT',
    ),
  ];
}
