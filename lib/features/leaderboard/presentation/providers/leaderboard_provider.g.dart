// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LeaderboardNotifier)
final leaderboardProvider = LeaderboardNotifierProvider._();

final class LeaderboardNotifierProvider
    extends $NotifierProvider<LeaderboardNotifier, LeaderboardState> {
  LeaderboardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardNotifierHash();

  @$internal
  @override
  LeaderboardNotifier create() => LeaderboardNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardState>(value),
    );
  }
}

String _$leaderboardNotifierHash() =>
    r'73e8a35eef1947ef3797e3a6f1dd9167fbf64e16';

abstract class _$LeaderboardNotifier extends $Notifier<LeaderboardState> {
  LeaderboardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeaderboardState, LeaderboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeaderboardState, LeaderboardState>,
              LeaderboardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
