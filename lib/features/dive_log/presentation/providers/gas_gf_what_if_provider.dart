import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/features/dive_log/data/services/profile_analysis_service.dart';
import 'package:submersion/features/dive_log/domain/services/gas_gf_what_if.dart';
import 'package:submersion/features/dive_log/presentation/providers/profile_analysis_provider.dart';

/// Key of one what-if run: a dive and the gas/GF the diver wants to try.
typedef GasGfWhatIfRequest = ({String diveId, GasGfOverrides overrides});

/// Replays the dive's logged samples through the same analysis pipeline the
/// dive detail page uses, with [GasGfWhatIfRequest.overrides] applied to a copy
/// of the dive. Nothing is saved: the dive row, its tanks and its gas switches
/// are untouched, so an empty override set reproduces [profileAnalysisProvider]
/// exactly (residual tissue and CNS from earlier dives included).
///
/// Mirrors the series choice in [profileAnalysisProvider]: on a multi-computer
/// dive that is the primary source's own samples, never the interleaved ones.
final gasGfWhatIfAnalysisProvider =
    FutureProvider.family<ProfileAnalysis?, GasGfWhatIfRequest>((
      ref,
      request,
    ) async {
      final dive = await ref.watch(analysisDiveProvider(request.diveId).future);
      if (dive == null || dive.profile.isEmpty) return null;
      final series = await ref.watch(
        diveAnalysisSeriesProvider(request.diveId).future,
      );
      if (series == null) return null;

      final modified = applyGasGfOverrides(dive, request.overrides);
      final own = series.sourceProfile;
      final source = series.source;
      if (own == null || source == null) {
        return computeAnalysisForProfile(ref, modified, series.points);
      }
      return computeAnalysisForProfile(
        ref,
        modified,
        own.points,
        computerId: own.computerId,
        sourceId: own.sourceId,
        decoSource: source.isPrimary ? null : source,
        perSource: true,
      );
    });
