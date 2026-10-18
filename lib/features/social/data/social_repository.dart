import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/social_profile.dart';

class SocialRepository {
  SocialRepository(this.client);
  final SupabaseClient client;
  Future<SocialProfile?> profile(String id) async {
    final row = await client.rpc(
      'get_social_profile',
      params: {'p_public_id': id},
    );
    return row == null
        ? null
        : SocialProfile.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> action(String id, String action) async {
    await client.rpc(
      'social_action',
      params: {'p_public_id': id, 'p_action': action},
    );
  }

  Future<List<SocialProfile>> connections(String kind, {int offset = 0}) async {
    final rows = await client.rpc(
      'list_social_connections',
      params: {'p_kind': kind, 'p_offset': offset},
    );
    return (rows as List)
        .map((r) => SocialProfile.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> visibility(String value) =>
      client.rpc('set_social_visibility', params: {'p_visibility': value});
}
