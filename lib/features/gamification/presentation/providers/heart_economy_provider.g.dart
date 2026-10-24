// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'heart_economy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HeartEconomy)
final heartEconomyProvider = HeartEconomyProvider._();

final class HeartEconomyProvider extends $NotifierProvider<HeartEconomy, int> {
  HeartEconomyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'heartEconomyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$heartEconomyHash();

  @$internal
  @override
  HeartEconomy create() => HeartEconomy();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$heartEconomyHash() => r'aeace34acbf2cf5cabf6a94ffbcef2c87f87264f';

abstract class _$HeartEconomy extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
