import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:streak/features/auth/data/repositories/auth_repository.dart';

@GenerateMocks([SupabaseClient, GoTrueClient, User])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuthClient;
  late MockUser mockUser;
  late AuthRepository authRepository;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthClient = MockGoTrueClient();
    mockUser = MockUser();
    
    when(mockSupabaseClient.auth).thenReturn(mockAuthClient);
    
    authRepository = AuthRepository(supabaseClient: mockSupabaseClient);
  });

  group('AuthRepository', () {
    test('completeOnboarding throws when user is not authenticated', () async {
      when(mockAuthClient.currentUser).thenReturn(null);

      expect(
        () => authRepository.completeOnboarding(
          username: 'test',
          avatarId: 'avatar_01',
          district: 'Pune',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
