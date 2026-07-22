/// Body regions a healthy-skin contribution photo can be tagged with.
///
/// Values match `BODY_REGIONS` in the review dashboard
/// (review_dashboard/src/data/types.ts) exactly — the dashboard reads these
/// slugs directly from Firestore, so they must stay identical on both sides.
enum BodyRegion {
  forearm,
  upperArm,
  lowerLeg,
  torso,
  face,
  hand,
  neck,
}

extension BodyRegionExtension on BodyRegion {
  /// Stable slug stored in Firestore/SQLite — must match the dashboard schema.
  String get id {
    switch (this) {
      case BodyRegion.forearm:
        return 'forearm';
      case BodyRegion.upperArm:
        return 'upper_arm';
      case BodyRegion.lowerLeg:
        return 'lower_leg';
      case BodyRegion.torso:
        return 'torso';
      case BodyRegion.face:
        return 'face';
      case BodyRegion.hand:
        return 'hand';
      case BodyRegion.neck:
        return 'neck';
    }
  }

  static BodyRegion fromId(String id) {
    return BodyRegion.values.firstWhere(
      (BodyRegion r) => r.id == id,
      orElse: () => throw ArgumentError('Unknown body region id: $id'),
    );
  }
}
