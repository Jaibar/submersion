import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/dive_log/presentation/providers/profile_legend_provider.dart';

void main() {
  group('ProfileLegendState', () {
    group('sectionExpanded', () {
      test('defaults to expected initial values', () {
        const state = ProfileLegendState();
        expect(state.sectionExpanded['overlays'], true);
        expect(state.sectionExpanded['decompression'], true);
        expect(state.sectionExpanded['markers'], false);
        expect(state.sectionExpanded['gasAnalysis'], false);
        expect(state.sectionExpanded['other'], false);
        expect(state.sectionExpanded['tankPressures'], true);
      });

      test('copyWith preserves sectionExpanded', () {
        const state = ProfileLegendState();
        final updated = state.copyWith(
          sectionExpanded: {...state.sectionExpanded, 'markers': true},
        );
        expect(updated.sectionExpanded['markers'], true);
        expect(updated.sectionExpanded['overlays'], true);
      });

      test('equality includes sectionExpanded', () {
        const state1 = ProfileLegendState();
        final state2 = state1.copyWith(
          sectionExpanded: {...state1.sectionExpanded, 'markers': true},
        );
        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
