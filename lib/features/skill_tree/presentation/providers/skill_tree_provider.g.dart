// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_tree_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SkillTreeNotifier)
final skillTreeProvider = SkillTreeNotifierProvider._();

final class SkillTreeNotifierProvider
    extends $AsyncNotifierProvider<SkillTreeNotifier, List<SkillUnit>> {
  SkillTreeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillTreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillTreeNotifierHash();

  @$internal
  @override
  SkillTreeNotifier create() => SkillTreeNotifier();
}

String _$skillTreeNotifierHash() => r'fc439e088a5a6ab9c82c384e803ac63e0e5462ba';

abstract class _$SkillTreeNotifier extends $AsyncNotifier<List<SkillUnit>> {
  FutureOr<List<SkillUnit>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SkillUnit>>, List<SkillUnit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SkillUnit>>, List<SkillUnit>>,
              AsyncValue<List<SkillUnit>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
