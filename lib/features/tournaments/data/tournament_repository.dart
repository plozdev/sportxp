import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/tournament.dart';

abstract class TournamentRepository {
  Future<List<Tournament>> listTournaments({String? filter});
  Future<void> registerTournament(String tournamentId, {String? partnerId});
}

class SupabaseTournamentRepository implements TournamentRepository {
  SupabaseTournamentRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<Tournament>> listTournaments({String? filter}) async {
    try {
      var query = client.from('tournaments').select('*');
      if (filter != null && filter != 'all') {
        query = query.eq('status', filter);
      }
      final rows = await query.order('start_date', ascending: true);
      return (rows as List)
          .map((r) => Tournament.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (_) {
      // Fallback khi bảng chưa chạy migration
      return _fallbackTournaments;
    }
  }

  @override
  Future<void> registerTournament(String tournamentId, {String? partnerId}) async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Vui lòng đăng nhập để đăng ký giải đấu.');

    final payload = <String, dynamic>{
      'tournament_id': tournamentId,
      'user_id': user.id,
      'status': 'registered',
    };
    if (partnerId != null) {
      payload['partner_id'] = partnerId;
    }
    await client.from('tournament_participants').insert(payload);
  }

  static final List<Tournament> _fallbackTournaments = [
    Tournament(
      id: 'e1111111-1111-1111-1111-111111111111',
      title: 'SportXP Open Championship 2026',
      venueName: 'Sân Cầu Lông Kỳ Hòa, Quận 10',
      address: 'Sư Vạn Hạnh, Phường 12, Quận 10, TP.HCM',
      format: 'doubles',
      entryFee: 200000,
      prizePool: 5000000,
      maxSlots: 32,
      currentSlots: 18,
      startDate: DateTime.now().add(const Duration(days: 14)),
      status: 'registering',
      minTier: 'TB',
      maxTier: 'Khá+',
    ),
    Tournament(
      id: 'e2222222-2222-2222-2222-222222222222',
      title: 'Cúp Tân Binh Phong Trào - Đĩa Bạc',
      venueName: 'Sân Cầu Lông Đào Duy Anh',
      address: 'Đào Duy Anh, Phú Nhuận, TP.HCM',
      format: 'doubles',
      entryFee: 150000,
      prizePool: 3000000,
      maxSlots: 16,
      currentSlots: 12,
      startDate: DateTime.now().add(const Duration(days: 7)),
      status: 'registering',
      minTier: 'Nhập môn',
      maxTier: 'TBY+',
    ),
    Tournament(
      id: 'e3333333-3333-3333-3333-333333333333',
      title: 'Super Smash Master - Đơn Nam',
      venueName: 'Sân Cầu Lông Kim Cương',
      address: 'Thủ Đức, TP.HCM',
      format: 'singles',
      entryFee: 250000,
      prizePool: 8000000,
      maxSlots: 16,
      currentSlots: 16,
      startDate: DateTime.now().add(const Duration(days: 3)),
      status: 'ongoing',
      minTier: 'Khá-',
      maxTier: 'Cao thủ phong trào',
    ),
  ];
}
