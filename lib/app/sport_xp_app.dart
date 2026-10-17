import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../features/matchmaking/domain/live_match_repository.dart';
import '../features/onboarding/presentation/onboarding_gate.dart';
import 'sport_xp_shell.dart';

class SportXpApp extends StatelessWidget {
  const SportXpApp({super.key, this.client, this.matches, this.startupError});
  final SupabaseClient? client;
  final LiveMatchRepository? matches;
  final String? startupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SportXP',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: OnboardingGate(
      client: client,
      child: SportXpShell(
        client: client,
        matches: matches,
        startupError: startupError,
      ),
    ),
  );
}
