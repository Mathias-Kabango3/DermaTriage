import '../../core/constants/body_regions.dart';

/// Local sync state for a queued contribution — distinct from the Firestore
/// document's own `status` (pending/approved/rejected, set by the
/// dermatologist reviewer). This tracks only "has this device gotten it to
/// the server yet".
enum ContributionSyncStatus {
  queued,
  uploaded;

  String get id => name;

  static ContributionSyncStatus fromId(String id) =>
      ContributionSyncStatus.values.firstWhere((s) => s.id == id);
}

/// A volunteer-submitted healthy-skin photo, captured offline and queued
/// locally until connectivity allows the upload to Cloudinary (photo) +
/// Firestore (metadata). Mirrors the `healthy_skin_contributions` collection the review
/// dashboard reads (review_dashboard/src/data/types.ts,
/// docs/review_dashboard_schema.md) — this local row *becomes* that document
/// once uploaded, using the same id.
class HealthySkinContribution {
  /// Also used as the Firestore document id once uploaded.
  final String id;
  final String localPhotoPath;
  final int fitzpatrickType; // 1-6
  final BodyRegion bodyRegion;
  final String contributorId; // CHW's Firebase uid — not a real name
  final String facility;
  final DateTime capturedAt;
  final ContributionSyncStatus syncStatus;
  final String? lastError;

  const HealthySkinContribution({
    required this.id,
    required this.localPhotoPath,
    required this.fitzpatrickType,
    required this.bodyRegion,
    required this.contributorId,
    required this.facility,
    required this.capturedAt,
    this.syncStatus = ContributionSyncStatus.queued,
    this.lastError,
  });

  static const List<String> _romanNumerals = <String>[
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
  ];

  /// Fitzpatrick type as the Roman-numeral string the dashboard expects
  /// ("I".."VI"), converted from the 1-6 int used elsewhere in this app.
  String get fitzpatrickRoman => _romanNumerals[fitzpatrickType - 1];

  HealthySkinContribution copyWith({
    ContributionSyncStatus? syncStatus,
    String? lastError,
  }) {
    return HealthySkinContribution(
      id: id,
      localPhotoPath: localPhotoPath,
      fitzpatrickType: fitzpatrickType,
      bodyRegion: bodyRegion,
      contributorId: contributorId,
      facility: facility,
      capturedAt: capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Local SQLite row.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'local_photo_path': localPhotoPath,
      'fitzpatrick_type': fitzpatrickType,
      'body_region': bodyRegion.id,
      'contributor_id': contributorId,
      'facility': facility,
      'captured_at': capturedAt.toIso8601String(),
      'sync_status': syncStatus.id,
      'last_error': lastError,
    };
  }

  factory HealthySkinContribution.fromMap(Map<String, dynamic> map) {
    return HealthySkinContribution(
      id: map['id'] as String,
      localPhotoPath: map['local_photo_path'] as String,
      fitzpatrickType: map['fitzpatrick_type'] as int,
      bodyRegion: BodyRegionExtension.fromId(map['body_region'] as String),
      contributorId: map['contributor_id'] as String,
      facility: map['facility'] as String,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      syncStatus: ContributionSyncStatus.fromId(map['sync_status'] as String),
      lastError: map['last_error'] as String?,
    );
  }

  // Deliberately no toFirestoreMap() here: the dashboard reads `submittedAt`
  // as a Firestore Timestamp (review_dashboard/src/data/firestoreRepo.ts
  // `toDate()`), and this app may queue a contribution offline for days
  // before it uploads — so the document must be built where
  // `cloud_firestore`'s `Timestamp.fromDate(capturedAt)` is available (the
  // upload service), not as a plain ISO string here. A string would silently
  // read back as epoch on the dashboard side instead of throwing.
}
