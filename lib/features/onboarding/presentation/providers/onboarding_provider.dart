import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/state/user_state.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../profile/data/repositories/progress_repository.dart';

part 'onboarding_provider.g.dart';

enum UsernameStatus { idle, checking, available, taken, invalidFormat, error }

class OnboardingState {
  final int currentStep;
  final String username;
  final UsernameStatus usernameStatus;
  final String? selectedAvatarId;
  final String? selectedDistrict;
  final bool isSubmitting;

  OnboardingState({
    this.currentStep = 0,
    this.username = '',
    this.usernameStatus = UsernameStatus.idle,
    this.selectedAvatarId,
    this.selectedDistrict,
    this.isSubmitting = false,
  });

  bool get isCurrentStepValid {
    if (currentStep == 0) return usernameStatus == UsernameStatus.available;
    if (currentStep == 1) return selectedAvatarId != null;
    if (currentStep == 2) return selectedDistrict != null;
    return false;
  }

  OnboardingState copyWith({
    int? currentStep,
    String? username,
    UsernameStatus? usernameStatus,
    String? selectedAvatarId,
    String? selectedDistrict,
    bool? isSubmitting,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      username: username ?? this.username,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      selectedAvatarId: selectedAvatarId ?? this.selectedAvatarId,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  late final AuthRepository _authRepository;
  Timer? _debounceTimer;

  @override
  OnboardingState build() {
    _authRepository = ref.read(authRepositoryProvider);
    
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    
    return OnboardingState();
  }

  void nextStep() {
    if (state.isCurrentStepValid && state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setAvatar(String avatarId) {
    state = state.copyWith(selectedAvatarId: avatarId);
  }

  void setDistrict(String district) {
    state = state.copyWith(selectedDistrict: district);
  }

  void onUsernameChanged(String value) {
    final cleanValue = value.trim();
    
    state = state.copyWith(
      username: cleanValue,
      usernameStatus: UsernameStatus.checking,
    );

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _validateUsername(cleanValue);
    });
  }

  Future<void> _validateUsername(String username) async {
    // 1. Regex validation: 3-15 chars, lowercase, numbers, underscores
    final isValidFormat = RegExp(r'^[a-z0-9_]{3,15}$').hasMatch(username);
    
    if (!isValidFormat) {
      state = state.copyWith(usernameStatus: UsernameStatus.invalidFormat);
      return;
    }

    // 2. Supabase availability check
    try {
      final isAvailable = await _authRepository.checkUsernameAvailable(username);
      
      if (state.username == username) {
        state = state.copyWith(
          usernameStatus: isAvailable ? UsernameStatus.available : UsernameStatus.taken,
        );
      }
    } catch (e) {
      if (state.username == username) {
        state = state.copyWith(usernameStatus: UsernameStatus.error);
      }
    }
  }

  Future<bool> submitProfile() async {
    if (!state.isCurrentStepValid) return false;
    
    state = state.copyWith(isSubmitting: true);
    
    try {
      await _authRepository.completeOnboarding(
        username: state.username,
        avatarId: state.selectedAvatarId!,
        district: state.selectedDistrict!,
      );
      
      // Update local state
      ref.read(userStoreProvider.notifier).updateUsername(state.username);
      await ProgressRepository().saveLocalState('is_onboarded', '1');
      
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      print('Onboarding Error: $e');
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}
