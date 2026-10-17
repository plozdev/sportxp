import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/sport_xp_app.dart';
import 'core/config/supabase_config.dart';
import 'features/matchmaking/data/supabase_match_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = SupabaseConfig.fromEnvironment();
  SupabaseClient? client;
  String? startupError;
  if (config.isValid) {
    try {
      await Supabase.initialize(
        url: config.url,
        publishableKey: config.anonKey,
      );
      client = Supabase.instance.client;
    } catch (_) {
      startupError = 'Không thể khởi tạo kết nối. Vui lòng mở lại ứng dụng.';
    }
  } else {
    startupError = 'Chưa cấu hình SUPABASE_URL và SUPABASE_ANON_KEY.';
  }
  runApp(
    SportXpApp(
      client: client,
      matches: client == null ? null : SupabaseMatchRepository(client),
      startupError: startupError,
    ),
  );
}
