import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/player_profile.dart';

class ProfileRepository {
  ProfileRepository(this.client);
  final SupabaseClient client;
  static const columns =
      'id, display_name, elo_rating, tier_name, trust_score, win_streak';

  Future<PlayerProfile?> currentProfile() async {
    final id = client.auth.currentUser?.id;
    if (id == null) return null;
    final row = await client
        .from('profiles')
        .select(columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : PlayerProfile.fromJson(row);
  }

  Future<List<PlayerProfile>> leaderboard() async {
    final rows = await client
        .from('profiles')
        .select(columns)
        .not('elo_rating', 'is', null)
        .eq('onboarding_step', 5)
        .order('elo_rating', ascending: false)
        .order('id', ascending: true)
        .limit(100);
    return rows.map(PlayerProfile.fromJson).toList(growable: false);
  }
}
