// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MistakeNotifier)
final mistakeProvider = MistakeNotifierProvider._();

final class MistakeNotifierProvider
    extends $NotifierProvider<MistakeNotifier, MistakeState> {
  MistakeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mistakeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mistakeNotifierHash();

  @$internal
  @override
  MistakeNotifier create() => MistakeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MistakeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MistakeState>(value),
    );
  }
}

String _$mistakeNotifierHash() => r'11abcc47f59ab6938203a019f3595966c793d2c4';

abstract class _$MistakeNotifier extends $Notifier<MistakeState> {
  MistakeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MistakeState, MistakeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MistakeState, MistakeState>,
              MistakeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
