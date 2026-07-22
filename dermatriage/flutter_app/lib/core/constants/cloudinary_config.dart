/// Image hosting for healthy-skin contribution photos.
///
/// Firebase Storage now requires the project to be on the Blaze
/// (pay-as-you-go) billing plan even to use its free-tier quota — Google
/// changed this in late 2024. Rather than require the project owner to add
/// a credit card, contribution photos are uploaded directly to Cloudinary
/// instead. Auth + Firestore (patient/encounter data, contribution
/// metadata) are unaffected — this only replaces where the photo *bytes*
/// live.
///
/// Cloud name and unsigned preset ("dermatriage") are configured — verified
/// with a real end-to-end upload (2026-07-22).
///
/// These two values are not secrets — an unsigned preset is designed to be
/// embedded in a distributed app — but note the real security trade-off:
/// unlike the old Firebase Storage rules (which checked
/// `request.auth.uid == contributorId`), Cloudinary's unsigned upload has
/// **no per-user check** — anyone who extracts these two strings from the
/// compiled app (trivial) can upload to this Cloudinary account. Mitigate
/// with the upload preset's own restrictions (folder, format, max size,
/// moderation) rather than relying on app-side secrecy.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'drnqxbbx6';
  static const String uploadPreset = 'dermatriage';

  static Uri get uploadEndpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
}
