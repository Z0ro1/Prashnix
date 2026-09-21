// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_questions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavedQuestionsNotifier)
final savedQuestionsProvider = SavedQuestionsNotifierProvider._();

final class SavedQuestionsNotifierProvider
    extends
        $AsyncNotifierProvider<SavedQuestionsNotifier, List<QuestionModel>> {
  SavedQuestionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedQuestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedQuestionsNotifierHash();

  @$internal
  @override
  SavedQuestionsNotifier create() => SavedQuestionsNotifier();
}

String _$savedQuestionsNotifierHash() =>
    r'2e88eda6990a4d186c423ac091854f8db761f997';

abstract class _$SavedQuestionsNotifier
    extends $AsyncNotifier<List<QuestionModel>> {
  FutureOr<List<QuestionModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<QuestionModel>>, List<QuestionModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<QuestionModel>>, List<QuestionModel>>,
              AsyncValue<List<QuestionModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
