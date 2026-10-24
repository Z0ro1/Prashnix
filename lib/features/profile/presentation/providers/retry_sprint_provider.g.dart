// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retry_sprint_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RetrySprintNotifier)
final retrySprintProvider = RetrySprintNotifierFamily._();

final class RetrySprintNotifierProvider
    extends $NotifierProvider<RetrySprintNotifier, RetryState> {
  RetrySprintNotifierProvider._({
    required RetrySprintNotifierFamily super.from,
    required List<QuestionModel> super.argument,
  }) : super(
         retry: null,
         name: r'retrySprintProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$retrySprintNotifierHash();

  @override
  String toString() {
    return r'retrySprintProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RetrySprintNotifier create() => RetrySprintNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RetryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RetryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RetrySprintNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$retrySprintNotifierHash() =>
    r'7321b5777be116f531ae920973b85fdfca6cd7af';

final class RetrySprintNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RetrySprintNotifier,
          RetryState,
          RetryState,
          RetryState,
          List<QuestionModel>
        > {
  RetrySprintNotifierFamily._()
    : super(
        retry: null,
        name: r'retrySprintProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RetrySprintNotifierProvider call(List<QuestionModel> initialQuestions) =>
      RetrySprintNotifierProvider._(argument: initialQuestions, from: this);

  @override
  String toString() => r'retrySprintProvider';
}

abstract class _$RetrySprintNotifier extends $Notifier<RetryState> {
  late final _$args = ref.$arg as List<QuestionModel>;
  List<QuestionModel> get initialQuestions => _$args;

  RetryState build(List<QuestionModel> initialQuestions);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RetryState, RetryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RetryState, RetryState>,
              RetryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
