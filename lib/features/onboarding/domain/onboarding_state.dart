class OnboardingState {
  OnboardingState({
    required this.step,
    required List<int> answers,
    required this.displayName,
    this.eloRating,
    this.tierName,
  }) : answers = List.unmodifiable(answers) {
    if (step < 0 ||
        step > 5 ||
        (step < 5 && step != answers.length) ||
        (step == 5 && eloRating == null)) {
      throw ArgumentError('Tiến độ onboarding không hợp lệ.');
    }
  }
  final int step;
  final List<int> answers;
  final String displayName;
  final int? eloRating;
  final String? tierName;
  bool get completed => step == 5;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      OnboardingState(
        step: (json['onboarding_step'] as num).toInt(),
        answers: (json['answers'] as List)
            .map((v) => (v as num).toInt())
            .toList(),
        displayName: json['display_name'] as String,
        eloRating: (json['elo_rating'] as num?)?.toInt(),
        tierName: json['tier_name'] as String?,
      );
}
