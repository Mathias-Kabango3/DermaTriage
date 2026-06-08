/// Domain entity for a patient — pure business object, no persistence concerns.
class Patient {
  final String id;
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
}
