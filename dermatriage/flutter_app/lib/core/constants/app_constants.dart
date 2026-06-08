/// Application-wide constants for DermaTriage.
class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'DermaTriage';

  // Model / inference
  static const String modelAssetPath =
      'assets/models/skin_triage_model.tflite';
  static const int imageSize = 224;
  static const int numClasses = 12;

  // Local database
  static const String databaseName = 'dermatriage.db';
  static const int databaseVersion = 1;

  /// Short disclaimer for the persistent banner (see [ethicsDisclaimer] for
  /// the full text shown on first launch).
  static const String disclaimer =
      'Not a diagnostic tool. AI suggestions support — never replace — '
      'clinical judgement. When in doubt, refer the patient.';

  /// Ethics & safety disclaimer (proposal Section 4.4).
  ///
  /// Shown to the community health worker on first launch and accessible from
  /// the results screen. DermaTriage is a decision-support aid, not a
  /// diagnostic device.
  static const String ethicsDisclaimer =
      'DermaTriage is a clinical decision-support tool intended to assist '
      'trained community health workers. It is NOT a diagnostic device and '
      'does not replace examination, diagnosis, or treatment by a qualified '
      'healthcare professional.\n\n'
      'The AI model provides a provisional triage suggestion based on a '
      'photograph of a skin lesion. Its predictions may be incorrect, '
      'especially for conditions, skin tones, lighting, or image quality not '
      'well represented in its training data. A "treat locally" suggestion '
      'never rules out serious disease.\n\n'
      'Always use your own clinical judgement. When in doubt, or if a lesion '
      'is changing, bleeding, painful, or the patient is concerned, refer the '
      'patient to a clinician. Any suspicion of cancer must be referred '
      'urgently regardless of the app\'s suggestion.\n\n'
      'Patient images and data are stored only on this device and are used '
      'solely to support the current encounter. Obtain the patient\'s informed '
      'consent before capturing any image. By continuing, you confirm that you '
      'understand these limitations and accept responsibility for all clinical '
      'decisions.';
}
