import 'onboarding_state.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingState> load();
  Future<OnboardingState> saveAnswer(int questionIndex, int choiceIndex);
}
