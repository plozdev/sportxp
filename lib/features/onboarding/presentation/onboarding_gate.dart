import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/bento_card.dart';
import '../data/supabase_onboarding_repository.dart';
import '../domain/onboarding_repository.dart';
import '../domain/onboarding_state.dart';
import 'onboarding_page.dart';

/// Checks restored sessions as well as fresh sign-ins. Guests may browse.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({
    super.key,
    required this.client,
    required this.child,
    this.repository,
  });
  final SupabaseClient? client;
  final Widget child;
  final OnboardingRepository? repository;
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  StreamSubscription<AuthState>? _subscription;
  Future<OnboardingState>? _state;
  OnboardingRepository? _repository;
  String? _userId;
  @override
  void initState() {
    super.initState();
    final client = widget.client;
    _repository =
        widget.repository ??
        (client == null ? null : SupabaseOnboardingRepository(client));
    _userId = client?.auth.currentUser?.id;
    if (_userId != null) _load();
    _subscription = client?.auth.onAuthStateChange.listen(
      (event) {
        final userId = event.session?.user.id;
        if (!mounted || _userId == userId) return;
        setState(() {
          _userId = userId;
          _state = null;
          if (userId != null) _load();
        });
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _userId = client.auth.currentUser?.id;
            _load();
          });
        }
      },
    );
  }

  void _load() {
    if (_userId == null || _repository == null) return;
    final future = _repository!.load();
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {}));
    _state = future;
  }

  Future<void> _signOut() async {
    try {
      await widget.client?.auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa thể đăng xuất. Vui lòng thử lại.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return widget.child;
    return FutureBuilder<OnboardingState>(
      future: _state,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Đang tải hồ sơ',
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('SPORTXP')),
            body: SafeArea(
              child: PageContent(
                children: [
                  const BentoCard(
                    child: Text(
                      'Chưa tải được tiến độ của bạn. Kiểm tra kết nối và thử lại để tiếp tục.',
                    ),
                  ),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text('THỬ LẠI'),
                  ),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            ),
          );
        }
        final state = snapshot.data!;
        if (state.completed) return widget.child;
        return OnboardingPage(
          key: ValueKey(_userId),
          initialState: state,
          repository: _repository!,
          onSignOut: _signOut,
          onComplete: () => setState(_load),
        );
      },
    );
  }
}
