// Phase 2 verification: reference bank loading + retrieval scoring, run
// against the real bundled 120-case bank (not a synthetic one — the timing
// budget is specifically for the bank the app actually ships).

import 'dart:convert';

import 'package:dermatriage/data/datasources/reference/reference_bank.dart';
import 'package:dermatriage/data/models/reference_case.dart';
import 'package:dermatriage/services/retrieval/retrieval_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

List<double> _embeddingOf(List<dynamic> items, int index) =>
    ((items[index] as Map<String, dynamic>)['embedding'] as List<dynamic>)
        .map((dynamic e) => (e as num).toDouble())
        .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReferenceBank bank;
  late List<dynamic> rawItems;

  setUpAll(() async {
    final String jsonStr =
        await rootBundle.loadString(RetrievalService.bankAsset);
    bank = ReferenceBank.fromJsonString(jsonStr);
    rawItems =
        (jsonDecode(jsonStr) as Map<String, dynamic>)['items'] as List<dynamic>;
  });

  test('bank loads all 120 cases at feat_dim 576', () {
    expect(bank.featDim, 576);
    expect(bank.cases.length, 120);
  });

  test('topMatches returns at most one match per subjectId', () {
    final List<double> query = _embeddingOf(rawItems, 0);
    final List<ReferenceMatch> matches = bank.topMatches(query, k: 5);
    final Set<String> subjects =
        matches.map((ReferenceMatch m) => m.reference.subjectId).toSet();
    expect(subjects.length, matches.length,
        reason: 'no two matches should share a subjectId');
  });

  test('querying with a stored embedding retrieves that exact case first', () {
    final Map<String, dynamic> item = rawItems[7] as Map<String, dynamic>;
    final List<double> query = _embeddingOf(rawItems, 7);

    final List<ReferenceMatch> matches = bank.topMatches(query, k: 3);
    expect(matches, isNotEmpty);
    expect(matches.first.reference.file, item['file']);
    expect(matches.first.similarity, closeTo(1.0, 1e-4));
  });

  test('rejects a query embedding of the wrong length', () {
    expect(
      () => bank.topMatches(List<double>.filled(10, 0.0)),
      throwsArgumentError,
    );
  });

  test('scores the real 120-case bank well under the 50ms budget', () {
    final List<double> query = _embeddingOf(rawItems, 3);

    final Stopwatch stopwatch = Stopwatch()..start();
    bank.topMatches(query, k: 3);
    stopwatch.stop();
    // ignore: avoid_print
    print('topMatches over ${bank.cases.length} cases: '
        '${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(50));
  });

  test('majorityLabel breaks ties toward the highest-ranked match', () {
    ReferenceMatch m(String label, double sim) => ReferenceMatch(
          reference: ReferenceCase(
              file: 'x.jpg',
              label: label,
              subjectId: 's$label$sim',
              fitzpatrick: 3),
          similarity: sim,
        );
    final List<ReferenceMatch> tied = <ReferenceMatch>[
      m('fungal', 0.9),
      m('eczema', 0.85),
      m('fungal', 0.8),
    ];
    expect(RetrievalService.majorityLabel(tied), 'fungal');

    final List<ReferenceMatch> allDifferent = <ReferenceMatch>[
      m('fungal', 0.9),
      m('eczema', 0.85),
      m('scabies', 0.8),
    ];
    // No majority — falls back to the top-ranked match's label.
    expect(RetrievalService.majorityLabel(allDifferent), 'fungal');

    expect(RetrievalService.majorityLabel(<ReferenceMatch>[]), isNull);
  });

  group('RetrievalService', () {
    test('happy path: loads the bundled bank and returns ranked matches',
        () async {
      final RetrievalService service = RetrievalService();
      final List<double> query = _embeddingOf(rawItems, 10);

      final RetrievalResult result = await service.retrieve(query, k: 3);
      expect(result.isEmpty, isFalse);
      expect(result.matches.length, 3);
      expect(result.majorityLabel, isNotNull);
    });

    test('malformed bank JSON fails to parse without crashing the caller',
        () {
      expect(
        () => ReferenceBank.fromJsonString('{not valid json'),
        throwsFormatException,
      );
    });
  });
}
