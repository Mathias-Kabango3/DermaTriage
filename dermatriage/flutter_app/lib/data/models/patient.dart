/// SQLite-backed data model for a patient record.
///
/// Booleans are stored as integers (0/1) and [createdAt] as an ISO-8601
/// string, matching the `patients` table schema.
class Patient {
  final String id; // UUID
  final int? approximateAge;
  final String sex;
  final String location;
  final int fitzpatrickType; // 1–6
  final bool consentGiven;
  final bool photoConsent;
  final DateTime createdAt;

  const Patient({
    required this.id,
    this.approximateAge,
    required this.sex,
    required this.location,
    required this.fitzpatrickType,
    required this.consentGiven,
    required this.photoConsent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'approximate_age': approximateAge,
      'sex': sex,
      'location': location,
      'fitzpatrick_type': fitzpatrickType,
      'consent_given': consentGiven ? 1 : 0,
      'photo_consent': photoConsent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      approximateAge: map['approximate_age'] as int?,
      sex: map['sex'] as String,
      location: map['location'] as String,
      fitzpatrickType: map['fitzpatrick_type'] as int,
      consentGiven: (map['consent_given'] as int) == 1,
      photoConsent: (map['photo_consent'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Patient copyWith({
    String? id,
    int? approximateAge,
    String? sex,
    String? location,
    int? fitzpatrickType,
    bool? consentGiven,
    bool? photoConsent,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      approximateAge: approximateAge ?? this.approximateAge,
      sex: sex ?? this.sex,
      location: location ?? this.location,
      fitzpatrickType: fitzpatrickType ?? this.fitzpatrickType,
      consentGiven: consentGiven ?? this.consentGiven,
      photoConsent: photoConsent ?? this.photoConsent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
