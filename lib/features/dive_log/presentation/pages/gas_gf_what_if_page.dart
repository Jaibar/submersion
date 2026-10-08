import 'package:flutter/material.dart';

import 'package:submersion/core/providers/provider.dart';
import 'package:submersion/core/utils/unit_formatter.dart';
import 'package:submersion/features/dive_3d/application/tissue_providers.dart';
import 'package:submersion/features/dive_log/data/services/profile_analysis_service.dart';
import 'package:submersion/features/dive_log/domain/entities/dive.dart';
import 'package:submersion/features/dive_log/domain/services/gas_gf_what_if.dart';
import 'package:submersion/features/dive_log/presentation/providers/gas_gf_what_if_provider.dart';
import 'package:submersion/features/dive_log/presentation/providers/profile_analysis_provider.dart';
import 'package:submersion/features/dive_log/presentation/widgets/gas_gf_ceiling_chart.dart';
import 'package:submersion/features/dive_log/presentation/widgets/tissue_area_chart.dart';
import 'package:submersion/features/dive_log/presentation/widgets/tissue_color_schemes.dart';
import 'package:submersion/features/settings/presentation/providers/settings_providers.dart';
import 'package:submersion/l10n/l10n_extension.dart';

/// "What if: gas and GF" for one logged dive.
///
/// Re-runs the dive's real samples through the dive-detail analysis with a
/// different oxygen percentage and/or gradient factors and sets the result
/// beside the dive as logged: shortest NDL, deepest ceiling, peak tissue
/// loading, CNS, plus the tissue-loading and ceiling charts. The profile is
/// never re-planned, so every difference comes from the gas/GF change alone.
class GasGfWhatIfPage extends ConsumerStatefulWidget {
  const GasGfWhatIfPage({super.key, required this.diveId});

  final String diveId;

  @override
  ConsumerState<GasGfWhatIfPage> createState() => _GasGfWhatIfPageState();
}

class _GasGfWhatIfPageState extends ConsumerState<GasGfWhatIfPage> {
  static const _o2Presets = [21.0, 28.0, 32.0, 36.0, 40.0];

  /// Null fields = as logged. Committed values; they key the analysis.
  GasGfOverrides _overrides = const GasGfOverrides();

  /// Live slider positions while dragging; the analysis only re-runs on
  /// release.
  double? _dragO2;
  double? _dragGfLow;
  double? _dragGfHigh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final units = UnitFormatter(ref.watch(settingsProvider));
    final diveAsync = ref.watch(analysisDiveProvider(widget.diveId));
    final seriesAsync = ref.watch(diveAnalysisSeriesProvider(widget.diveId));
    final logged = ref.watch(
      gasGfWhatIfAnalysisProvider((
        diveId: widget.diveId,
        overrides: const GasGfOverrides(),
      )),
    );
    final whatIf = ref.watch(
      gasGfWhatIfAnalysisProvider((
        diveId: widget.diveId,
        overrides: _overrides,
      )),
    );

    final dive = diveAsync.value;
    final loggedAnalysis = logged.value;
    final whatIfAnalysis = whatIf.value;
    final points = seriesAsync.value?.points;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diveLog_gasGfWhatIf_title)),
      body: (dive == null || loggedAnalysis == null || points == null)
          ? Center(
              child: (logged.isLoading || diveAsync.isLoading)
                  ? const CircularProgressIndicator()
                  : Text(l10n.diveLog_gasGfWhatIf_noProfile),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _controls(context, dive, loggedAnalysis),
                const SizedBox(height: 16),
                if (whatIfAnalysis == null)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _summary(
                    context,
                    loggedAnalysis,
                    whatIfAnalysis,
                    points,
                    units,
                  ),
                  const SizedBox(height: 16),
                  _ceilingCard(
                    context,
                    loggedAnalysis,
                    whatIfAnalysis,
                    points,
                    units,
                  ),
                  const SizedBox(height: 16),
                  _tissueCard(
                    context,
                    l10n.diveLog_gasGfWhatIf_loggedLabel,
                    loggedAnalysis,
                  ),
                  const SizedBox(height: 12),
                  _tissueCard(
                    context,
                    l10n.diveLog_gasGfWhatIf_whatIfLabel,
                    whatIfAnalysis,
                  ),
                ],
              ],
            ),
    );
  }

  // ---- controls ----------------------------------------------------------

  Widget _controls(
    BuildContext context,
    Dive dive,
    ProfileAnalysis loggedAnalysis,
  ) {
    final l10n = context.l10n;
    final loggedO2 = firstTank(dive)?.gasMix.o2 ?? 21.0;
    final loggedLow = (loggedAnalysis.gfSource?.low ?? 30).toDouble();
    final loggedHigh = (loggedAnalysis.gfSource?.high ?? 70).toDouble();

    final o2 = _dragO2 ?? _overrides.o2Percent ?? loggedO2;
    final gfLow = _dragGfLow ?? _overrides.gfLow?.toDouble() ?? loggedLow;
    final gfHigh = _dragGfHigh ?? _overrides.gfHigh?.toDouble() ?? loggedHigh;

    void commitO2(double v) => setState(() {
      _dragO2 = null;
      _overrides = v.round() == loggedO2.round()
          ? _overrides.copyWith(clearO2: true)
          : _overrides.copyWith(o2Percent: v.roundToDouble());
    });

    // Keep low <= high: moving one past the other drags the other along.
    void commitGf({double? low, double? high}) => setState(() {
      var l = low ?? _overrides.gfLow?.toDouble() ?? loggedLow;
      var h = high ?? _overrides.gfHigh?.toDouble() ?? loggedHigh;
      if (low != null && l > h) h = l;
      if (high != null && h < l) l = h;
      _dragGfLow = null;
      _dragGfHigh = null;
      _overrides = GasGfOverrides(
        o2Percent: _overrides.o2Percent,
        gfLow: l.round() == loggedLow.round() ? null : l.round(),
        gfHigh: h.round() == loggedHigh.round() ? null : h.round(),
      );
    });

    Widget slider({
      required String label,
      required String value,
      required double current,
      required double min,
      required double max,
      required ValueChanged<double> onDrag,
      required ValueChanged<double> onEnd,
    }) => Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(
            value: current.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onDrag,
            onChangeEnd: onEnd,
          ),
        ),
        SizedBox(width: 48, child: Text(value, textAlign: TextAlign.end)),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.diveLog_gasGfWhatIf_loggedLabel}: '
              'O2 ${loggedO2.round()}%, '
              'GF ${loggedLow.round()}/${loggedHigh.round()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in _o2Presets)
                  ChoiceChip(
                    label: Text(p == 21 ? 'Air' : 'EAN${p.round()}'),
                    selected: o2.round() == p.round(),
                    onSelected: (_) => commitO2(p),
                  ),
              ],
            ),
            slider(
              label: l10n.diveLog_gasGfWhatIf_o2Label,
              value: '${o2.round()}%',
              current: o2,
              min: 15,
              max: 60,
              onDrag: (v) => setState(() => _dragO2 = v),
              onEnd: commitO2,
            ),
            slider(
              label: l10n.diveLog_gasGfWhatIf_gfLowLabel,
              value: '${gfLow.round()}',
              current: gfLow,
              min: 10,
              max: 100,
              onDrag: (v) => setState(() => _dragGfLow = v),
              onEnd: (v) => commitGf(low: v),
            ),
            slider(
              label: l10n.diveLog_gasGfWhatIf_gfHighLabel,
              value: '${gfHigh.round()}',
              current: gfHigh,
              min: 10,
              max: 100,
              onDrag: (v) => setState(() => _dragGfHigh = v),
              onEnd: (v) => commitGf(high: v),
            ),
            Text(
              l10n.diveLog_gasGfWhatIf_firstCylinderNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _overrides.isEmpty
                    ? null
                    : () => setState(() => _overrides = const GasGfOverrides()),
                child: Text(l10n.diveLog_gasGfWhatIf_reset),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- results -----------------------------------------------------------

  String _ndl(
    BuildContext context,
    GasGfWhatIfSummary s,
    List<DiveProfilePoint> pts,
  ) {
    if (s.minNdlSeconds < 0) return context.l10n.diveLog_gasGfWhatIf_decoShort;
    final minutes = '${(s.minNdlSeconds / 60).floor()} min';
    if (s.minNdlIndex >= pts.length) return minutes;
    final at = pts[s.minNdlIndex].timestamp - pts.first.timestamp;
    final ss = (at % 60).toString().padLeft(2, '0');
    return '$minutes @ ${at ~/ 60}:$ss';
  }

  Widget _summary(
    BuildContext context,
    ProfileAnalysis loggedAnalysis,
    ProfileAnalysis whatIfAnalysis,
    List<DiveProfilePoint> points,
    UnitFormatter units,
  ) {
    final l10n = context.l10n;
    final a = GasGfWhatIfSummary.fromAnalysis(loggedAnalysis);
    final b = GasGfWhatIfSummary.fromAnalysis(whatIfAnalysis);
    final yes = l10n.diveLog_gasGfWhatIf_yes;
    final no = l10n.diveLog_gasGfWhatIf_no;

    // A what-if value that is worse than the logged one is highlighted.
    TableRow row(String label, String x, String y, {bool worse = false}) =>
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(label),
            ),
            Text(x),
            Text(
              y,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: worse ? Colors.deepOrange : null,
              ),
            ),
          ],
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diveLog_gasGfWhatIf_metricsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.4),
                1: FlexColumnWidth(1.3),
                2: FlexColumnWidth(1.3),
              },
              children: [
                row(
                  '',
                  l10n.diveLog_gasGfWhatIf_loggedLabel,
                  l10n.diveLog_gasGfWhatIf_whatIfLabel,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_minNdl,
                  _ndl(context, a, points),
                  _ndl(context, b, points),
                  worse: b.minNdlSeconds < a.minNdlSeconds,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_maxCeiling,
                  units.formatDepth(a.maxCeilingMeters),
                  units.formatDepth(b.maxCeilingMeters),
                  worse: b.maxCeilingMeters > a.maxCeilingMeters,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_decoObligation,
                  a.hadDeco ? yes : no,
                  b.hadDeco ? yes : no,
                  worse: b.hadDeco && !a.hadDeco,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_peakTissue,
                  '${a.peakTissueLoadingPercent.round()}%',
                  '${b.peakTissueLoadingPercent.round()}%',
                  worse:
                      b.peakTissueLoadingPercent > a.peakTissueLoadingPercent,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_cnsEnd,
                  '${a.cnsEndPercent.round()}%',
                  '${b.cnsEndPercent.round()}%',
                  worse: b.cnsEndPercent > a.cnsEndPercent,
                ),
                row(
                  l10n.diveLog_gasGfWhatIf_maxPpO2,
                  '${a.maxPpO2.toStringAsFixed(2)} bar',
                  '${b.maxPpO2.toStringAsFixed(2)} bar',
                  worse: b.maxPpO2 > a.maxPpO2,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (b.cnsEndPercent / 100).clamp(0.0, 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ceilingCard(
    BuildContext context,
    ProfileAnalysis loggedAnalysis,
    ProfileAnalysis whatIfAnalysis,
    List<DiveProfilePoint> points,
    UnitFormatter units,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.diveLog_gasGfWhatIf_ceilingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GasGfCeilingChart(
              profile: points,
              loggedCeiling: loggedAnalysis.ceilingCurve,
              whatIfCeiling: whatIfAnalysis.ceilingCurve,
              units: units,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tissueCard(
    BuildContext context,
    String label,
    ProfileAnalysis analysis,
  ) {
    final colorFn = colorFnForScheme(ref.watch(tissueColorSchemeProvider));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.l10n.diveLog_gasGfWhatIf_tissueTitle} - $label',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (analysis.decoStatuses.isNotEmpty)
              TissueAreaChart(
                decoStatuses: analysis.decoStatuses,
                colorFn: colorFn,
                isExpanded: true,
                height: 120,
              ),
          ],
        ),
      ),
    );
  }
}
