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
    extends $NotifierProvider<SkillTreeNotifier, List<SkillUnit>> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SkillUnit> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SkillUnit>>(value),
    );
  }
}

String _$skillTreeNotifierHash() => r'b300e32a2a7266945fdb9e66666b85f27761ce79';

abstract class _$SkillTreeNotifier extends $Notifier<List<SkillUnit>> {
  List<SkillUnit> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<SkillUnit>, List<SkillUnit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SkillUnit>, List<SkillUnit>>,
              List<SkillUnit>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
