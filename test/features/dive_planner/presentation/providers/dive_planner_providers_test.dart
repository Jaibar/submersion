import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/core/constants/units.dart';
import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/features/dive_planner/domain/entities/plan_result.dart';
import 'package:submersion/features/dive_planner/presentation/providers/dive_planner_providers.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';

class _TestSettingsNotifier extends StateNotifier<AppSettings>
    implements SettingsNotifier {
  _TestSettingsNotifier({PressureUnit pressureUnit = PressureUnit.bar})
    : super(AppSettings(pressureUnit: pressureUnit));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('divePlanNotifierProvider', () {
    test('uses ~34 bar reserve when pressure unit is psi', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => _TestSettingsNotifier(pressureUnit: PressureUnit.psi),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(divePlanNotifierProvider);
      // 500 psi ≈ 34.47 bar
      expect(state.reservePressure, closeTo(34.47, 0.5));
    });

    test('uses 50 bar reserve when pressure unit is bar', () {
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(divePlanNotifierProvider);
      expect(state.reservePressure, DivePlanState.kDefaultReservePressureBar);
    });
  });
}
