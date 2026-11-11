// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserStore)
final userStoreProvider = UserStoreProvider._();

final class UserStoreProvider extends $NotifierProvider<UserStore, UserModel> {
  UserStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStoreHash();

  @$internal
  @override
  UserStore create() => UserStore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserModel>(value),
    );
  }
}

String _$userStoreHash() => r'a307d1dd7c72f90c5777268a33aa24ef192bdce9';

abstract class _$UserStore extends $Notifier<UserModel> {
  UserModel build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UserModel, UserModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UserModel, UserModel>,
              UserModel,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
