import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/bento_card.dart';
import '../domain/onboarding_quiz.dart';
import '../domain/onboarding_repository.dart';
import '../domain/onboarding_state.dart';
import '../../rankings/domain/rank_tier.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.initialState,
    required this.repository,
    required this.onComplete,
    required this.onSignOut,
  });
  final OnboardingState initialState;
  final OnboardingRepository repository;
  final VoidCallback onComplete, onSignOut;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late OnboardingState _state;
  late int _index;
  int? _selected;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _index = _state.step.clamp(0, 4);
  }

  Future<void> _answer(int choice) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _selected = choice;
      _error = null;
    });
    try {
      // Start saving immediately; keep the selected state visible briefly.
      final state = await widget.repository.saveAnswer(_index, choice);
      if (!mounted) return;
      if (!MediaQuery.disableAnimationsOf(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 160));
      }
      if (!mounted) return;
      setState(() {
        _state = state;
        _index = state.step.clamp(0, 4);
        _selected = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa lưu được câu trả lời. Kết nối lại và thử tiếp nhé.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() {
    if (_saving || _index == 0) return;
    setState(() {
      _index--;
      _selected = _state.answers[_index];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final compactSignOut = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SPORTXP'),
          actions: [
            if (compactSignOut)
              IconButton(
                onPressed: _saving ? null : widget.onSignOut,
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
              )
            else
              TextButton(
                onPressed: _saving ? null : widget.onSignOut,
                child: const Text('Đăng xuất'),
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTokens.contentWidth,
              ),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: reducedMotion ? 0 : 240),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween(
                          begin: const Offset(.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: child,
                  ),
                ),
                child: _state.completed ? _result() : _question(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _question() {
    final question = OnboardingQuiz.questions[_index];
    return ListView(
      key: ValueKey('question-$_index'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('Bước ${_index + 1}/5', style: AppTokens.label),
            if (_index > 0)
              TextButton.icon(
                onPressed: _saving ? null : _back,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Câu trước'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Tiến trình onboarding',
          value: 'Bước ${_index + 1} trên 5',
          child: LinearProgressIndicator(
            value: (_index + 1) / 5,
            minHeight: 3,
            backgroundColor: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          question.category.toUpperCase(),
          style: AppTokens.label.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            question.title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Chọn câu gần với bạn nhất. Mỗi câu trả lời giúp tìm đối thủ vừa sức.',
          style: AppTokens.label,
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < question.choices.length; i++) ...[
          _choice(i, question.choices[i].label),
          const SizedBox(height: 12),
        ],
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: const TextStyle(color: AppColors.loss)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving || _selected == null
                  ? null
                  : () => _answer(_selected!),
              icon: const Icon(Icons.refresh),
              label: const Text('Lưu lại câu trả lời'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            _saving
                ? 'Đang lưu câu trả lời…'
                : 'Tiến độ được lưu sau mỗi câu trả lời.',
            style: AppTokens.label,
          ),
        ),
      ],
    );
  }

  Widget _choice(int index, String label) {
    final selected = _selected == index;
    return Semantics(
      enabled: !_saving,
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _saving ? null : () => _answer(index),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  String.fromCharCode(65 + index),
                  style: AppTokens.label.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _result() {
    final elo = _state.eloRating!;
    final capped =
        _state.answers.length == 5 &&
        OnboardingQuiz.rawElo(_state.answers) >
            OnboardingQuiz.maximumInitialElo;
    return ListView(
      key: const ValueKey('onboarding-result'),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.sports_tennis, size: 36, color: AppColors.muted),
        const SizedBox(height: 24),
        Text(
          'Điểm xuất phát của bạn.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Kỹ năng được ghi nhận. Hành trình bắt đầu từ sân đấu.',
          style: AppTokens.label,
        ),
        const SizedBox(height: 28),
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('THẺ VẬN ĐỘNG VIÊN', style: AppTokens.label),
                  ),
                  const Icon(
                    Icons.shield_outlined,
                    color: AppColors.muted,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _state.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(
                '$elo',
                style: AppTokens.metric.copyWith(fontSize: 56, height: 1),
              ),
              const SizedBox(height: 8),
              const Text('ELO KHỞI TẠO · TẠM TÍNH', style: AppTokens.label),
              const Divider(height: 40),
              Text(
                RankTier.fromElo(elo).label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unverified · Chưa xác minh',
                        style: AppTokens.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Hoàn thành 5 trận đấu đầu tiên để mở khóa Huy hiệu Rank chính thức và xuất hiện trên Bảng xếp hạng khu vực!',
          style: TextStyle(height: 1.5),
        ),
        if (capped) ...[
          const SizedBox(height: 12),
          const Text(
            'Điểm khởi tạo tối đa là 850 Elo. Hãy chứng minh trình độ qua những trận thắng thực tế để tiến tới mốc 1000+.',
            style: AppTokens.label,
          ),
        ],
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: widget.onComplete,
            child: const Text('BẮT ĐẦU LÊN SÂN', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
