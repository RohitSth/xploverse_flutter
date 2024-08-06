// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booked_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$totalBookedAmountHash() => r'952fe80a14e50345eff649793c6920090e181bd5';

/// See also [totalBookedAmount].
@ProviderFor(totalBookedAmount)
final totalBookedAmountProvider = AutoDisposeProvider<double>.internal(
  totalBookedAmount,
  name: r'totalBookedAmountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalBookedAmountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalBookedAmountRef = AutoDisposeProviderRef<double>;
String _$bookedNotifierHash() => r'16e897ed89e494e84934969a24cadcaf747188a9';

/// See also [BookedNotifier].
@ProviderFor(BookedNotifier)
final bookedNotifierProvider =
    AutoDisposeNotifierProvider<BookedNotifier, Set<Event>>.internal(
  BookedNotifier.new,
  name: r'bookedNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BookedNotifier = AutoDisposeNotifier<Set<Event>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
