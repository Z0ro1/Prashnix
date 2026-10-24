import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prashnix/features/auth/data/repositories/auth_repository.dart';
import 'package:prashnix/features/onboarding/presentation/providers/onboarding_provider.dart';

@GenerateMocks([AuthRepository])
import 'onboarding_provider_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
    // Keep the provider alive
    container.listen(onboardingProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
  });

  group('OnboardingNotifier Validation', () {
    test('username regex validation fails on uppercase', () async {
      final notifier = container.read(onboardingProvider.notifier);
      
      notifier.onUsernameChanged('Saurabh'); // Has uppercase
      
      // Wait for debounce (300ms)
      await Future.delayed(const Duration(milliseconds: 350));
      final state = container.read(onboardingProvider);
      expect(state.usernameStatus, UsernameStatus.invalidFormat);
    });

    test('username regex validation fails on short length', () async {
      final notifier = container.read(onboardingProvider.notifier);
      
      notifier.onUsernameChanged('ab'); // Too short
      
      await Future.delayed(const Duration(milliseconds: 350));
      final state = container.read(onboardingProvider);
      expect(state.usernameStatus, UsernameStatus.invalidFormat);
    });

    test('username regex validation passes on valid format', () async {
      final notifier = container.read(onboardingProvider.notifier);
      
      // We need to mock auth repository so it doesn't fail
      when(mockAuthRepository.checkUsernameAvailable(any))
          .thenAnswer((_) async => true);
          
      notifier.onUsernameChanged('saurabh_123'); // Valid
      
      await Future.delayed(const Duration(milliseconds: 350));
      final state = container.read(onboardingProvider);
      expect(state.usernameStatus, isNot(UsernameStatus.invalidFormat));
    });

    test('step advancement logic', () {
      final notifier = container.read(onboardingProvider.notifier);
      
      // Step 0 -> 1 requires valid username
      notifier.nextStep();
      expect(container.read(onboardingProvider).currentStep, 0); // Should be blocked
      
      // Force valid username state via hack or mock?
      // Since state is read-only from outside, we can't easily force it without mocking.
      // But we can test Avatar and District selection state.
      notifier.setAvatar('avatar_01');
      expect(container.read(onboardingProvider).selectedAvatarId, 'avatar_01');

      notifier.setDistrict('Pune');
      expect(container.read(onboardingProvider).selectedDistrict, 'Pune');
    });
  });
}
