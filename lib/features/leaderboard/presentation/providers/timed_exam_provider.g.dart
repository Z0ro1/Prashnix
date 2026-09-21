// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timed_exam_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimedExamNotifier)
final timedExamProvider = TimedExamNotifierProvider._();

final class TimedExamNotifierProvider
    extends $NotifierProvider<TimedExamNotifier, TimedExamState> {
  TimedExamNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timedExamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timedExamNotifierHash();

  @$internal
  @override
  TimedExamNotifier create() => TimedExamNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimedExamState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimedExamState>(value),
    );
  }
}

String _$timedExamNotifierHash() => r'5f96596ca15dc01b1ca3a2f46c0730bb5b2d7ad5';

abstract class _$TimedExamNotifier extends $Notifier<TimedExamState> {
  TimedExamState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TimedExamState, TimedExamState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TimedExamState, TimedExamState>,
              TimedExamState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
