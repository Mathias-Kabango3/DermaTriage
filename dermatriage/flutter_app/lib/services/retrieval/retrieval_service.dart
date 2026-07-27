import 'dart:developer' as developer;

import 'package:flutter/services.dart' show rootBundle;

import '../../data/datasources/reference/reference_bank.dart';
import '../../data/models/reference_case.dart';

/// Outcome of a single retrieval query.
class RetrievalResult {
  final List<ReferenceMatch> matches;
  final String? majorityLabel;

  const RetrievalResult(this.matches, this.majorityLabel);

  static const RetrievalResult empty = RetrievalResult(<ReferenceMatch>[], null);

  bool get isEmpty => matches.isEmpty;
}

/// Loads the bundled reference bank and answers nearest-neighbour case
/// retrieval queries. Never touches the network; the bank ships as an app
/// asset. Failures (missing/corrupt bank) are swallowed — retrieval is a
/// supplementary explainability layer and must never block triage.
class RetrievalService {
  static const String bankAsset = 'assets/reference/reference_bank.json';

  ReferenceBank? _bank;
  bool _loadFailed = false;
  Future<void>? _loading;

  /// Lazily load the bank on first use (not at app start). Safe to call
  /// repeatedly; concurrent calls share the same in-flight load.
  Future<void> ensureLoaded() {
    if (_bank != null || _loadFailed) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final String jsonStr = await rootBundle.loadString(bankAsset);
      _bank = ReferenceBank.fromJsonString(jsonStr);
    } catch (e, st) {
      _loadFailed = true;
      developer.log('Reference bank failed to load — retrieval disabled',
          name: 'RetrievalService', error: e, stackTrace: st);
    }
  }

  /// Top-[k] confirmed cases matching [queryEmbedding], or [RetrievalResult.empty]
  /// if the bank is unavailable.
  Future<RetrievalResult> retrieve(List<double> queryEmbedding, {int k = 3}) async {
    await ensureLoaded();
    final ReferenceBank? bank = _bank;
    if (bank == null) return RetrievalResult.empty;

    final Stopwatch stopwatch = Stopwatch()..start();
    final List<ReferenceMatch> matches = bank.topMatches(queryEmbedding, k: k);
    stopwatch.stop();
    developer.log('Retrieval: ${stopwatch.elapsedMilliseconds}ms '
        'over ${bank.cases.length} cases', name: 'RetrievalService');

    return RetrievalResult(matches, majorityLabel(matches));
  }

  /// Majority label among [matches], breaking ties by highest individual
  /// similarity (matches are already ranked best-first).
  static String? majorityLabel(List<ReferenceMatch> matches) {
    if (matches.isEmpty) return null;
    final Map<String, int> counts = <String, int>{};
    for (final ReferenceMatch m in matches) {
      counts[m.reference.label] = (counts[m.reference.label] ?? 0) + 1;
    }
    final int maxCount = counts.values.reduce((int a, int b) => a > b ? a : b);
    for (final ReferenceMatch m in matches) {
      if (counts[m.reference.label] == maxCount) return m.reference.label;
    }
    return matches.first.reference.label;
  }
}
