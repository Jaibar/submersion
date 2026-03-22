import 'package:flutter_test/flutter_test.dart';

import 'package:submersion/features/dive_planner/domain/entities/plan_result.dart';

PlanResult _result({int totalRuntime = 0, int ndlAtBottom = 0}) {
  return PlanResult(
    totalRuntime: totalRuntime,
    ttsAtBottom: 0,
    ndlAtBottom: ndlAtBottom,
    maxDepth: 0,
    maxCeiling: 0,
    avgDepth: 0,
    decoSchedule: const [],
    gasConsumptions: const [],
    warnings: const [],
    endTissueState: const [],
    segmentResults: const {},
    cnsEnd: 0,
    otuTotal: 0,
    maxPpO2: 0,
    hasDecoObligation: false,
  );
}

void main() {
  group('PlanResult formatting', () {
    test('runtimeFormatted includes hours when totalRuntime >= 3600', () {
      expect(_result(totalRuntime: 3661).runtimeFormatted, '01:01:01');
    });

    test(
      'ndlFormatted returns >99 min when ndlAtBottom exceeds 99 minutes',
      () {
        expect(_result(ndlAtBottom: 100 * 60).ndlFormatted, '>99 min');
      },
    );
  });
}
