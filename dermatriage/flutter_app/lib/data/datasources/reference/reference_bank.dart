import 'dart:convert';
import 'dart:typed_data';

import '../../models/reference_case.dart';

/// Bundled bank of confirmed reference cases (embeddings only — see
/// [ReferenceCase]) used for on-device nearest-neighbour case retrieval.
///
/// Embeddings are stored as one flat [Float32List] (`cases.length * featDim`)
/// rather than nested lists, so scoring a few hundred vectors stays fast.
class ReferenceBank {
  final int featDim;
  final List<ReferenceCase> cases;
  final Float32List _matrix;

  ReferenceBank._(this.featDim, this.cases, this._matrix);

  factory ReferenceBank.fromJsonString(String jsonStr) {
    final Map<String, dynamic> json =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    final int featDim = json['feat_dim'] as int;
    final List<dynamic> items = json['items'] as List<dynamic>;

    final List<ReferenceCase> cases = <ReferenceCase>[];
    final Float32List matrix = Float32List(items.length * featDim);

    for (int i = 0; i < items.length; i++) {
      final Map<String, dynamic> item = items[i] as Map<String, dynamic>;
      cases.add(ReferenceCase(
        file: item['file'] as String,
        label: item['label'] as String,
        subjectId: item['subject_id'] as String,
        fitzpatrick: item['fitzpatrick'] as int,
      ));
      final List<dynamic> embedding = item['embedding'] as List<dynamic>;
      final int base = i * featDim;
      for (int d = 0; d < featDim; d++) {
        matrix[base + d] = (embedding[d] as num).toDouble();
      }
    }

    return ReferenceBank._(featDim, cases, matrix);
  }

  /// Top [k] nearest cases to [query] by cosine similarity, at most one per
  /// `subjectId` (PASSION contributes multiple photos per patient — showing
  /// near-duplicates both looks broken and falsely implies corroboration).
  ///
  /// Both [query] and the bank's vectors are already L2-normalised, so cosine
  /// similarity is a plain dot product.
  List<ReferenceMatch> topMatches(List<double> query, {int k = 3}) {
    if (query.length != featDim) {
      throw ArgumentError(
          'Query embedding length ${query.length} != bank featDim $featDim');
    }

    final List<double> scores = List<double>.filled(cases.length, 0.0);
    for (int i = 0; i < cases.length; i++) {
      final int base = i * featDim;
      double dot = 0.0;
      for (int d = 0; d < featDim; d++) {
        dot += query[d] * _matrix[base + d];
      }
      scores[i] = dot;
    }

    final List<int> order = List<int>.generate(cases.length, (int i) => i)
      ..sort((int a, int b) => scores[b].compareTo(scores[a]));

    final List<ReferenceMatch> matches = <ReferenceMatch>[];
    final Set<String> seenSubjects = <String>{};
    for (final int i in order) {
      if (matches.length >= k) break;
      final ReferenceCase c = cases[i];
      if (!seenSubjects.add(c.subjectId)) continue;
      matches.add(ReferenceMatch(reference: c, similarity: scores[i]));
    }
    return matches;
  }
}
