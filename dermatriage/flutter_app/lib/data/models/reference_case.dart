/// One confirmed case from the bundled reference bank.
///
/// DEMO-ONLY: [assetPath] and the underlying `assets/reference/images/`
/// bundle are a temporary addition for the capstone defense demo, so the
/// panel can see the retrieval concept with real thumbnails. PASSION dataset
/// photos cannot be redistributed publicly — before any release build,
/// delete `assets/reference/images/`, drop the `assets/reference/images/`
/// line from pubspec.yaml, and remove the thumbnail row in
/// SimilarCasesSection (it already degrades to text-only automatically if
/// the image file is simply missing, via Image.asset's errorBuilder, but the
/// image bytes themselves must not ship in a public build regardless).
class ReferenceCase {
  final String file;
  final String label;
  final String subjectId;
  final int fitzpatrick;

  const ReferenceCase({
    required this.file,
    required this.label,
    required this.subjectId,
    required this.fitzpatrick,
  });

  /// DEMO-ONLY — see class doc comment.
  String get assetPath => 'assets/reference/images/$file';
}

/// A single nearest-neighbour result: which case, and how similar.
class ReferenceMatch {
  final ReferenceCase reference;

  /// Cosine similarity in [-1, 1] (in practice ~[0, 1] for this model).
  final double similarity;

  const ReferenceMatch({required this.reference, required this.similarity});

  /// Similarity as a rounded whole percentage for display.
  int get similarityPercent => (similarity * 100).round();
}
