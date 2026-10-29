import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/matchmaking/domain/live_match_repository.dart';
import '../features/onboarding/presentation/onboarding_gate.dart';
import '../features/social/domain/profile_link.dart';
import '../features/social/presentation/social_profile_page.dart';
import 'sport_xp_shell.dart';

class SportXpApp extends StatefulWidget {
  const SportXpApp({
    super.key,
    this.client,
    this.matches,
    this.startupError,
    this.showSplash = true,
  });
  final SupabaseClient? client;
  final LiveMatchRepository? matches;
  final String? startupError;
  final bool showSplash;
  @override
  State<SportXpApp> createState() => _SportXpAppState();
}

class _SportXpAppState extends State<SportXpApp> {
  final _navigator = GlobalKey<NavigatorState>();
  String? _pendingProfileId;
  late final _observer = _ProfileRouteObserver((id) => _pendingProfileId = id);
  StreamSubscription<Uri>? _links;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final links = AppLinks();
      _links = links.uriLinkStream.listen(
        (uri) => _open(uri.toString()),
        onError: (Object _) {},
      );
      links.getInitialLink().then((uri) {
        if (mounted && uri != null) _open(uri.toString());
      }, onError: (Object _) {});
    }
  }

  void _open(String link) {
    final id = ProfileLink.parse(link);
    if (id == null || _pendingProfileId == id) return;
    _pendingProfileId = id;
    // Login/onboarding may not have mounted the protected Navigator yet.
    // Its initial route callback consumes the pending target when ready.
    final navigator = _navigator.currentState;
    if (navigator != null) unawaited(navigator.pushNamed('/p/$id'));
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final id = ProfileLink.parse(settings.name ?? '/');
    final client = widget.client;
    final child = id != null && client != null
        ? SocialProfilePage(publicId: id, client: client)
        : SportXpShell(
            client: client,
            matches: widget.matches,
            startupError: widget.startupError,
          );
    return MaterialPageRoute<void>(settings: settings, builder: (_) => child);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SportXP',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    navigatorKey: _navigator,
    navigatorObservers: [_observer],
    builder: (context, child) => AuthGate(
      client: widget.client,
      startupError: widget.startupError,
      showSplash: widget.showSplash,
      child: OnboardingGate(client: widget.client, child: child!),
    ),
    onGenerateRoute: _route,
    onGenerateInitialRoutes: (name) {
      final id = _pendingProfileId ?? ProfileLink.parse(name);
      return [
        _route(const RouteSettings(name: '/')),
        if (id != null) _route(RouteSettings(name: '/p/$id')),
      ];
    },
  );
}

class _ProfileRouteObserver extends NavigatorObserver {
  _ProfileRouteObserver(this.onProfileChanged);
  final void Function(String?) onProfileChanged;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute && route.settings.name != null) {
      onProfileChanged(ProfileLink.parse(route.settings.name!));
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      onProfileChanged(ProfileLink.parse(previousRoute?.settings.name ?? '/'));
    }
  }
}
