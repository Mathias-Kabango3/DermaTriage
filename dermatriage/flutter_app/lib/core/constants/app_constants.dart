/// Application-wide constants for DermaTriage.
class AppConstants {
  AppConstants._();

  // App identity
  static const String appName = 'DermaTriage';
  static const String appVersion = '1.0.0';
  static const String modelVersionAssetPath = 'assets/models/model_version.txt';

  // Model / inference
  static const String modelAssetPath =
      'assets/models/dermatriage_diverse.tflite';
  static const int imageSize = 224;
  // MobileNetV3-Small distilled student: 5 classes
  // (Fungal, Scabies, Eczema, healthy_skin, not_skin).
  static const int numClasses = 5;

  /// Minimum top-class probability (after softmax) for the app to show a
  /// diagnosis. Below this the CHW is asked to retake the photo.
  static const double confidenceThreshold = 0.50;

  /// Target for on-device inference latency (preprocess + model run). The app
  /// flags any run over this budget so the <2 s requirement is verifiable.
  static const int inferenceBudgetMs = 2000;

  // Local database
  static const String databaseName = 'dermatriage.db';
  // v2 adds the offline `users` table for CHW authentication.
  // v3 adds `healthy_skin_contributions` — the local upload queue for the
  // data-flywheel contribution flow.
  // v4 adds `patients.name` — a CHW-entered patient name so encounters in
  // History are recognisable (previously only date + classification were
  // shown, with no way to tell which patient a record belonged to).
  static const int databaseVersion = 4;

  // Offline authentication
  /// Minimum length for CHW account passwords.
  static const int minPasswordLength = 6;

  /// Preset security questions offered during registration. Used as the
  /// offline "forgot password" recovery mechanism (no email/server).
  static const List<String> securityQuestions = <String>[
    'What town were you born in?',
    "What is your mother's first name?",
    'What was the name of your first school?',
    'What is the name of your first pet?',
    'What is your favourite food?',
  ];

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
