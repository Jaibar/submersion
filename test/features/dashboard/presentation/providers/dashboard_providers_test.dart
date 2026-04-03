import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:submersion/features/dive_log/presentation/providers/dive_providers.dart';

import '../../../../helpers/mock_providers.dart';

void main() {
  group('personalRecordsProvider', () {
    test('finds longest dive by effectiveRuntime', () async {
      final dives = [
        createTestDiveWithBottomTime(
          id: 'short',
          bottomTime: const Duration(minutes: 20),
          runtime: const Duration(minutes: 25),
          maxDepth: 15.0,
          waterTemp: 24.0,
        ),
        createTestDiveWithBottomTime(
          id: 'long',
          bottomTime: const Duration(minutes: 60),
          runtime: const Duration(minutes: 75),
          maxDepth: 25.0,
          waterTemp: 22.0,
        ),
        createTestDiveWithBottomTime(
          id: 'medium',
          bottomTime: const Duration(minutes: 40),
          runtime: const Duration(minutes: 50),
          maxDepth: 30.0,
          waterTemp: 20.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [divesProvider.overrideWith((ref) async => dives)],
      );
      addTearDown(container.dispose);

      final records = await container.read(personalRecordsProvider.future);

      expect(records.longestDive, isNotNull);
      expect(records.longestDive!.id, 'long');
      expect(records.longestDive!.effectiveRuntime!.inMinutes, 75);
    });

    test('falls back to bottomTime when runtime is null', () async {
      final dives = [
        createTestDiveWithBottomTime(
          id: 'no-runtime',
          bottomTime: const Duration(minutes: 30),
          runtime: null,
          maxDepth: 20.0,
        ),
        createTestDiveWithBottomTime(
          id: 'shorter',
          bottomTime: const Duration(minutes: 15),
          runtime: null,
          maxDepth: 15.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [divesProvider.overrideWith((ref) async => dives)],
      );
      addTearDown(container.dispose);

      final records = await container.read(personalRecordsProvider.future);

      expect(records.longestDive, isNotNull);
      expect(records.longestDive!.id, 'no-runtime');
    });

    test('prefers runtime over bottomTime for longest dive', () async {
      // Both dives have the same bottomTime, but different runtimes.
      // The dive with the longer runtime should win.
      final dives = [
        createTestDiveWithBottomTime(
          id: 'short-runtime',
          bottomTime: const Duration(minutes: 40),
          runtime: const Duration(minutes: 45),
          maxDepth: 20.0,
        ),
        createTestDiveWithBottomTime(
          id: 'long-runtime',
          bottomTime: const Duration(minutes: 40),
          runtime: const Duration(minutes: 70),
          maxDepth: 15.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [divesProvider.overrideWith((ref) async => dives)],
      );
      addTearDown(container.dispose);

      final records = await container.read(personalRecordsProvider.future);

      expect(records.longestDive, isNotNull);
      expect(records.longestDive!.id, 'long-runtime');
    });
  });
}
