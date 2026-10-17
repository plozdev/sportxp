import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/onboarding_repository.dart';
import '../domain/onboarding_state.dart';

class SupabaseOnboardingRepository implements OnboardingRepository {
  SupabaseOnboardingRepository(this.client);
  final SupabaseClient client;

  @override
  Future<OnboardingState> load() async {
    final json = await client.rpc('get_onboarding_state');
    return OnboardingState.fromJson(Map<String, dynamic>.from(json as Map));
  }

  @override
  Future<OnboardingState> saveAnswer(int questionIndex, int choiceIndex) async {
    final json = await client.rpc(
      'save_onboarding_answer',
      params: {
        'p_question_index': questionIndex,
        'p_choice_index': choiceIndex,
      },
    );
    return OnboardingState.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
