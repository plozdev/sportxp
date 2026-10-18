import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../splash/presentation/splash_screen.dart';
import 'auth_page.dart';

/// Wraps the entire Navigator, including any pushed sheets or social routes.
/// Shows the athletic SplashScreen on initial app boot before settling on Auth or Main app.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.client,
    required this.child,
    this.startupError,
    this.showSplash = true,
  });

  final SupabaseClient? client;
  final Widget child;
  final String? startupError;
  final bool showSplash;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  Timer? _expiry;
  String? _userId;
  late bool _splashCompleted = !widget.showSplash;

  @override
  void initState() {
    super.initState();
    _sync(widget.client?.auth.currentSession);
    _subscription = widget.client?.auth.onAuthStateChange.listen(
      (event) {
        if (mounted) setState(() => _sync(event.session));
      },
      onError: (Object _) {
        if (mounted) setState(() => _sync(widget.client?.auth.currentSession));
      },
    );
  }

  void _sync(Session? session) {
    _expiry?.cancel();
    _userId = session != null && !session.isExpired ? session.user.id : null;
    if (_userId != null && session?.expiresAt != null) {
      final remaining = DateTime.fromMillisecondsSinceEpoch(
        session!.expiresAt! * 1000,
      ).difference(DateTime.now());
      _expiry = Timer(remaining, () {
        if (mounted) setState(() => _sync(widget.client?.auth.currentSession));
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashCompleted) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _splashCompleted = true);
        },
      );
    }

    if (_userId == null) {
      // A separate auth Navigator supplies the Overlay needed by text inputs.
      // The protected Navigator is not mounted until a valid session exists.
      return Navigator(
        key: const ValueKey('authentication'),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => AuthPage(
            client: widget.client,
            startupError: widget.startupError,
          ),
        ),
      );
    }
    return KeyedSubtree(key: ValueKey(_userId), child: widget.child);
  }
}
