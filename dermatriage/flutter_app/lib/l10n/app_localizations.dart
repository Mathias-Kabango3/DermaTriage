import 'package:flutter/material.dart';

/// App strings in English (`en`) and Kinyarwanda (`rw`).
///
/// Lightweight, dependency-free localisation: [AppLocalizations.of] resolves the
/// active locale and each getter returns the right string, falling back to
/// English for any missing key.
///
/// NOTE: the Kinyarwanda translations are a first pass and should be reviewed by
/// a native speaker before release — especially clinical wording.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('rw'),
  ];

  /// Human-readable name of a language, in that language.
  static String nameOf(String code) => code == 'rw' ? 'Ikinyarwanda' : 'English';

  String _t(String key) {
    final Map<String, String> table = locale.languageCode == 'rw' ? _rw : _en;
    return table[key] ?? _en[key] ?? key;
  }

  // Bottom navigation
  String get navHome => _t('navHome');
  String get navNewTriage => _t('navNewTriage');
  String get navHistory => _t('navHistory');
  String get navProfile => _t('navProfile');

  // Home
  String get homeTagline => _t('homeTagline');
  String get homeStartTriage => _t('homeStartTriage');
  String get homeViewHistory => _t('homeViewHistory');

  // Account / common
  String get account => _t('account');
  String signedInAs(String name) => '${_t('signedInAs')} $name';
  String get logout => _t('logout');
  String get logoutTitle => _t('logoutTitle');
  String get logoutBody => _t('logoutBody');
  String get cancel => _t('cancel');

  // Settings
  String get settingsTitle => _t('settingsTitle');
  String get sectionAbout => _t('sectionAbout');
  String get appVersion => _t('appVersion');
  String get modelVersion => _t('modelVersion');
  String get sectionDisclaimer => _t('sectionDisclaimer');
  String get sectionData => _t('sectionData');
  String get resetAllData => _t('resetAllData');
  String get resetting => _t('resetting');
  String get resetTitle => _t('resetTitle');
  String get resetBody => _t('resetBody');
  String get deleteEverything => _t('deleteEverything');
  String get dataReset => _t('dataReset');

  // Language switcher
  String get sectionLanguage => _t('sectionLanguage');
  String get language => _t('language');
  String get chooseLanguage => _t('chooseLanguage');
  String get languageEnglish => _t('languageEnglish');
  String get languageKinyarwanda => _t('languageKinyarwanda');

  // Patient registration
  String get patientTitle => _t('patientTitle');
  String get sex => _t('sex');
  String sexLabel(String code) => code == 'M'
      ? _t('sexMale')
      : code == 'F'
          ? _t('sexFemale')
          : _t('sexOther');
  String get patientName => _t('patientName');
  String get patientNameHint => _t('patientNameHint');
  String get patientNameRequired => _t('patientNameRequired');
  String get unknownPatient => _t('unknownPatient');
  String approxAgeYears(int age) => '~$age ${_t('yearsAbbrev')}';
  String get ageRange => _t('ageRange');
  String get selectAgeRange => _t('selectAgeRange');
  String get location => _t('location');
  String get locationHint => _t('locationHint');
  String get locationRequired => _t('locationRequired');
  String get skinType => _t('skinType');
  String get skinTypeHint => _t('skinTypeHint');
  String fitzpatrickDescription(int type) => _t('fitz$type');
  String get consentAssessment => _t('consentAssessment');
  String get consentPhoto => _t('consentPhoto');
  String get continueToCapture => _t('continueToCapture');
  String get completeFields => _t('completeFields');

  // Common
  String get email => _t('email');
  String get password => _t('password');
  String get save => _t('save');
  String get emailRequired => _t('emailRequired');
  String get passwordRequired => _t('passwordRequired');
  String get validEmail => _t('validEmail');
  String get passwordsNoMatch => _t('passwordsNoMatch');
  String get regionDistrict => _t('regionDistrict');
  String get healthFacility => _t('healthFacility');
  String minPasswordHint(int n) => '${_t('minPasswordPrefix')} $n ${_t('characters')}';

  // Triage level badges
  String triageLabel(String id) {
    switch (id) {
      case 'URGENT_REFERRAL':
        return _t('triageUrgent');
      case 'MONITOR':
        return _t('triageMonitor');
      case 'TREAT_LOCALLY':
        return _t('triageTreatLocally');
      default:
        return id;
    }
  }

  // History
  String get historyTitle => _t('historyTitle');
  String get historyEmpty => _t('historyEmpty');
  String get detailTitle => _t('detailTitle');
  String get photoUnavailable => _t('photoUnavailable');
  String get chwNotes => _t('chwNotes');
  String confidencePercent(int percent) => '$percent% ${_t('confidenceWord')}';

  // Result
  String get triageResultTitle => _t('triageResultTitle');
  String get analysing => _t('analysing');
  String get somethingWrong => _t('somethingWrong');
  String get retry => _t('retry');
  String get retakePhoto => _t('retakePhoto');
  String get backToHome => _t('backToHome');
  String get chwNotesOptional => _t('chwNotesOptional');
  String get saveEncounter => _t('saveEncounter');
  String get saving => _t('saving');
  String get encounterSaved => _t('encounterSaved');
  String get noPatientSession => _t('noPatientSession');
  String get noImage => _t('noImage');
  String get notSkinTitle => _t('notSkinTitle');
  String get notSkinMsg => _t('notSkinMsg');
  String get healthyTitle => _t('healthyTitle');
  String get healthyMsg => _t('healthyMsg');
  String get lowConfTitle => _t('lowConfTitle');
  String lowConfMsg(int percent) =>
      '${_t('lowConfMsgA')} $percent% ${_t('lowConfMsgB')}';
  String get retakeTitle => _t('retakeTitle');
  String get retakeMsg => _t('retakeMsg');
  String inferenceLabel(String seconds) => '${_t('inferenceWord')}: $seconds s';
  String withinTarget(String sec) => '· ${_t('withinWord')} $sec s ${_t('targetWord')}';
  String overTarget(String sec) => '· ${_t('overWord')} $sec s ${_t('targetWord')}';

  // Login
  String get loginHeading => _t('loginHeading');
  String get enterEmail => _t('enterEmail');
  String get enterPassword => _t('enterPassword');
  String get logIn => _t('logIn');
  String get signingIn => _t('signingIn');
  String get pleaseWait => _t('pleaseWait');
  String get forgotPassword => _t('forgotPassword');
  String get continueWithGoogle => _t('continueWithGoogle');
  String get newHealthWorker => _t('newHealthWorker');
  String get register => _t('register');
  String get firstSignInInfo => _t('firstSignInInfo');

  // Register
  String get createAccount => _t('createAccount');
  String get creating => _t('creating');
  String get fullName => _t('fullName');
  String get yourNameHint => _t('yourNameHint');
  String get enterName => _t('enterName');
  String get enterRegion => _t('enterRegion');
  String get whereYouWorkHint => _t('whereYouWorkHint');
  String get enterFacility => _t('enterFacility');
  String get confirmPassword => _t('confirmPassword');
  String get accountCreated => _t('accountCreated');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get registerInternetInfo => _t('registerInternetInfo');

  // Forgot password
  String get forgotTitle => _t('forgotTitle');
  String get forgotIntro => _t('forgotIntro');
  String get enterYourEmail => _t('enterYourEmail');
  String get sendResetLink => _t('sendResetLink');
  String get sending => _t('sending');
  String get checkEmail => _t('checkEmail');
  String resetSent(String email) =>
      '${_t('resetSentA')} $email. ${_t('resetSentB')}';
  String get backToLogin => _t('backToLogin');

  // Profile
  String get profileTitle => _t('profileTitle');
  String get profileOnlineNote => _t('profileOnlineNote');
  String get yourDetails => _t('yourDetails');
  String get displayName => _t('displayName');
  String get saveDetails => _t('saveDetails');
  String get detailsSaved => _t('detailsSaved');
  String get updateEmail => _t('updateEmail');
  String get emailConfirmSent => _t('emailConfirmSent');
  String get changePasswordTitle => _t('changePasswordTitle');
  String get newPassword => _t('newPassword');
  String get confirmNewPassword => _t('confirmNewPassword');
  String get changePasswordBtn => _t('changePasswordBtn');
  String get passwordChanged => _t('passwordChanged');
  String get settings => _t('settingsTitle');

  // Camera
  String get cameraTitle => _t('cameraTitle');
  String get cameraPermission => _t('cameraPermission');
  String get cameraStartFailed => _t('cameraStartFailed');
  String get noCamera => _t('noCamera');
  String captureFailed(String e) => '${_t('captureFailed')}: $e';
  String get goBack => _t('goBack');
  String get tryAgain => _t('tryAgain');
  String get openAppSettings => _t('openAppSettings');

  // Healthy-skin contribution flow
  String get contributeCardLabel => _t('contributeCardLabel');
  String get contributeTitle => _t('contributeTitle');
  String get contributeIntro => _t('contributeIntro');
  String get bodyRegionLabel => _t('bodyRegionLabel');
  String bodyRegionName(String id) => _t('region_$id');
  String get contributionCameraGuidance => _t('contributionCameraGuidance');
  String get contributionSavedTitle => _t('contributionSavedTitle');
  String get contributionSavedMessageOnline => _t('contributionSavedMessageOnline');
  String get contributionSavedMessageOffline => _t('contributionSavedMessageOffline');
  String get viewMyContributions => _t('viewMyContributions');
  String get myContributionsTitle => _t('myContributionsTitle');
  String get noContributionsYet => _t('noContributionsYet');
  String get statusQueued => _t('statusQueued');
  String get statusUploaded => _t('statusUploaded');

  // Consent dialog
  String get consentTitle => _t('consentTitle');
  String get consentAgree => _t('consentAgree');
  String get consentPrototype => _t('consentPrototype');
  String get consentLegalIntro => _t('consentLegalIntro');
  String get consentLegalAnd => _t('consentLegalAnd');

  // Legal (Privacy Policy / Terms of Use)
  String get legalSection => _t('legalSection');
  String get privacyPolicyTitle => _t('privacyPolicyTitle');
  String get termsTitle => _t('termsTitle');
  String get kinyarwandaSummaryLabel => _t('kinyarwandaSummaryLabel');
  String get fullTextLabel => _t('fullTextLabel');

  static const Map<String, String> _en = <String, String>{
    'navHome': 'Home',
    'navNewTriage': 'New Triage',
    'navHistory': 'History',
    'navProfile': 'Profile',
    'homeTagline': 'Offline AI-assisted skin triage',
    'homeStartTriage': 'Start New Triage',
    'homeViewHistory': 'View History',
    'account': 'Account',
    'signedInAs': 'Signed in as',
    'logout': 'Log out',
    'logoutTitle': 'Log out?',
    'logoutBody': 'You will need to sign in again to continue.',
    'cancel': 'Cancel',
    'settingsTitle': 'Settings',
    'sectionAbout': 'About',
    'appVersion': 'App version',
    'modelVersion': 'Model version',
    'sectionDisclaimer': 'Disclaimer',
    'sectionData': 'Data',
    'resetAllData': 'Reset All Data',
    'resetting': 'Resetting...',
    'resetTitle': 'Reset all data?',
    'resetBody':
        'This permanently deletes all patients and encounters stored on this '
            'device. This cannot be undone.',
    'deleteEverything': 'Delete everything',
    'dataReset': 'All data has been reset.',
    'sectionLanguage': 'Language',
    'language': 'Language',
    'chooseLanguage': 'Choose your language',
    'languageEnglish': 'English',
    'languageKinyarwanda': 'Kinyarwanda',
    'patientTitle': 'New Patient',
    'sex': 'Sex',
    'sexMale': 'Male',
    'sexFemale': 'Female',
    'sexOther': 'Other',
    'patientName': 'Patient name',
    'patientNameHint': "Patient's full name",
    'patientNameRequired': 'Patient name is required',
    'unknownPatient': 'Unknown patient',
    'yearsAbbrev': 'yrs',
    'ageRange': 'Age range',
    'selectAgeRange': 'Select age range',
    'location': 'Location',
    'locationHint': 'Village / clinic / district',
    'locationRequired': 'Location is required',
    'skinType': 'Fitzpatrick skin type',
    'skinTypeHint': 'Tap a circle to select the closest skin tone.',
    'fitz1': 'Type I — Very fair skin; always burns, never tans.',
    'fitz2': 'Type II — Fair skin; usually burns, tans minimally.',
    'fitz3': 'Type III — Medium skin; sometimes burns, tans uniformly.',
    'fitz4': 'Type IV — Olive skin; rarely burns, tans easily.',
    'fitz5': 'Type V — Brown skin; very rarely burns, tans darkly.',
    'fitz6': 'Type VI — Deeply pigmented skin; never burns.',
    'consentAssessment':
        'I confirm the patient has given verbal and written consent for this '
            'assessment and photo.',
    'consentPhoto':
        'The patient consents to a photo being taken and stored on this device '
            'for the assessment.',
    'continueToCapture': 'Continue to Capture',
    'completeFields': 'Please complete sex, age range and skin type.',
    // Common
    'email': 'Email',
    'password': 'Password',
    'save': 'Save',
    'emailRequired': 'Email is required',
    'passwordRequired': 'Password is required',
    'validEmail': 'Please enter a valid email address',
    'passwordsNoMatch': 'Passwords do not match',
    'regionDistrict': 'Region / District',
    'healthFacility': 'Health facility',
    'minPasswordPrefix': 'Use at least',
    'characters': 'characters',
    // Triage levels
    'triageUrgent': 'Urgent Referral',
    'triageMonitor': 'Monitor',
    'triageTreatLocally': 'Treat Locally',
    // History
    'historyTitle': 'Encounter History',
    'historyEmpty': 'No encounters recorded yet',
    'detailTitle': 'Encounter Detail',
    'photoUnavailable': 'Photo unavailable',
    'chwNotes': 'CHW Notes',
    'confidenceWord': 'confidence',
    // Result
    'triageResultTitle': 'Triage Result',
    'analysing': 'Analysing lesion...',
    'somethingWrong': 'Something went wrong.',
    'retry': 'Retry',
    'retakePhoto': 'Retake Photo',
    'backToHome': 'Back to Home',
    'chwNotesOptional': 'CHW notes (optional)',
    'saveEncounter': 'Save Encounter',
    'saving': 'Saving...',
    'encounterSaved': 'Encounter saved.',
    'noPatientSession': 'No patient in session. Cannot save.',
    'noImage': 'No image',
    'notSkinTitle': 'This does not look like skin',
    'notSkinMsg': 'The image does not appear to show skin. Please take a clear, '
        'close-up photo of the affected skin area and try again.',
    'healthyTitle': 'This skin appears healthy',
    'healthyMsg': 'No skin condition was detected. If the patient still has a '
        'concern, retake the photo of the affected area or refer them to a '
        'clinician.',
    'lowConfTitle': 'Not confident enough',
    'lowConfMsgA': 'The app is not sure about this image (below',
    'lowConfMsgB': 'confidence). Please retake a clear, well-lit, close-up '
        'photo. If you are still concerned, refer the patient.',
    'retakeTitle': 'Please retake the photo',
    'retakeMsg': 'Please take a clear, close-up photo and try again.',
    'inferenceWord': 'Inference',
    'withinWord': 'within',
    'overWord': 'over',
    'targetWord': 'target',
    // Login
    'loginHeading': 'Sign in to continue',
    'enterEmail': 'Please enter your email',
    'enterPassword': 'Please enter your password',
    'logIn': 'Log In',
    'signingIn': 'Signing in...',
    'pleaseWait': 'Please wait...',
    'forgotPassword': 'Forgot password?',
    'continueWithGoogle': 'Continue with Google',
    'newHealthWorker': 'New health worker?',
    'register': 'Register',
    'firstSignInInfo':
        'The first sign-in needs internet. After that, the app works offline.',
    // Register
    'createAccount': 'Create Account',
    'creating': 'Creating...',
    'fullName': 'Full name',
    'yourNameHint': 'Your name',
    'enterName': 'Please enter your name',
    'enterRegion': 'Please enter your region',
    'whereYouWorkHint': 'Where you work',
    'enterFacility': 'Please enter your facility',
    'confirmPassword': 'Confirm password',
    'accountCreated': 'Account created. Welcome!',
    'alreadyHaveAccount': 'I already have an account',
    'registerInternetInfo': 'Creating your account needs internet this one '
        'time. After that, you can use the app offline.',
    // Forgot password
    'forgotTitle': 'Forgot Password',
    'forgotIntro': 'We will email you a link to reset your password. This '
        'needs an internet connection.',
    'enterYourEmail': 'Enter your email',
    'sendResetLink': 'Send Reset Link',
    'sending': 'Sending...',
    'checkEmail': 'Check your email',
    'resetSentA': 'We sent a reset link to',
    'resetSentB': 'Open it to set a new password, then come back and log in.',
    'backToLogin': 'Back to Log In',
    // Profile
    'profileTitle': 'My Profile',
    'profileOnlineNote': 'Account changes need internet. Triage works offline.',
    'yourDetails': 'Your details',
    'displayName': 'Display name',
    'saveDetails': 'Save Details',
    'detailsSaved': 'Your details have been saved.',
    'updateEmail': 'Update Email',
    'emailConfirmSent': 'We sent a confirmation link to your new email. Your '
        'email changes once you open it.',
    'changePasswordTitle': 'Change password',
    'newPassword': 'New password',
    'confirmNewPassword': 'Confirm new password',
    'changePasswordBtn': 'Change Password',
    'passwordChanged': 'Your password has been changed.',
    // Camera
    'cameraTitle': 'Camera',
    'cameraPermission':
        'Camera permission is required to capture a lesion photo.',
    'cameraStartFailed': 'Could not start the camera.',
    'noCamera': 'No camera is available on this device.',
    'captureFailed': 'Capture failed',
    'goBack': 'Go Back',
    'tryAgain': 'Try Again',
    'openAppSettings': 'Open App Settings',
    // Consent dialog
    'contributeCardLabel': 'Contribute Healthy Skin Photo',
    'contributeTitle': 'Contribute Healthy Skin Photo',
    'contributeIntro':
        'Help improve the model by photographing healthy (unaffected) skin. '
            'Select the Fitzpatrick type and body region, then take a photo.',
    'bodyRegionLabel': 'Body region',
    'region_forearm': 'Forearm',
    'region_upper_arm': 'Upper arm',
    'region_lower_leg': 'Lower leg',
    'region_torso': 'Torso',
    'region_face': 'Face',
    'region_hand': 'Hand',
    'region_neck': 'Neck',
    'contributionCameraGuidance': 'Fill the frame with the body region — a full arm or leg is fine',
    'contributionSavedTitle': 'Saved — thank you!',
    'contributionSavedMessageOnline':
        'This photo is uploading now. You can keep capturing more in the '
            'meantime.',
    'contributionSavedMessageOffline':
        'You\'re offline — this photo will upload automatically once '
            'you\'re back online. You can keep capturing more in the '
            'meantime.',
    'viewMyContributions': 'My Contributions',
    'myContributionsTitle': 'My Contributions',
    'noContributionsYet': 'You haven\'t contributed any photos yet.',
    'statusQueued': 'Queued — will upload when online',
    'statusUploaded': 'Uploaded',
    'consentTitle': 'Before you begin',
    'consentAgree': 'I understand and agree',
    'consentPrototype':
        'This app is a research prototype, not an approved medical device.',
    'consentLegalIntro': 'By continuing, you agree to our',
    'consentLegalAnd': 'and',
    'legalSection': 'Legal',
    'privacyPolicyTitle': 'Privacy Policy',
    'termsTitle': 'Terms of Use',
    'kinyarwandaSummaryLabel': 'Kinyarwanda summary',
    'fullTextLabel': 'Full text (English)',
  };

  static const Map<String, String> _rw = <String, String>{
    'navHome': 'Ahabanza',
    'navNewTriage': 'Isuzuma rishya',
    'navHistory': 'Amateka',
    'navProfile': 'Umwirondoro',
    'homeTagline': 'Isuzuma ry’uruhu rikoresha AI, ridakeneye interineti',
    'homeStartTriage': 'Tangira isuzuma rishya',
    'homeViewHistory': 'Reba amateka',
    'account': 'Konti',
    'signedInAs': 'Winjiye nka',
    'logout': 'Sohoka',
    'logoutTitle': 'Sohoka?',
    'logoutBody': 'Uzakenera kongera kwinjira kugira ngo ukomeze.',
    'cancel': 'Reka',
    'settingsTitle': 'Igenamiterere',
    'sectionAbout': 'Ibyerekeye',
    'appVersion': 'Verisiyo ya porogaramu',
    'modelVersion': 'Verisiyo ya modeli',
    'sectionDisclaimer': 'Itangazo ry’ingenzi',
    'sectionData': 'Amakuru',
    'resetAllData': 'Siba amakuru yose',
    'resetting': 'Birasibwa...',
    'resetTitle': 'Gusiba amakuru yose?',
    'resetBody':
        'Ibi bisiba burundu abarwayi bose n’amasuzuma abitswe kuri iyi telefone. '
            'Ntibishoboka gusubizwa inyuma.',
    'deleteEverything': 'Siba byose',
    'dataReset': 'Amakuru yose yasibwe.',
    'sectionLanguage': 'Ururimi',
    'language': 'Ururimi',
    'chooseLanguage': 'Hitamo ururimi',
    'languageEnglish': 'Icyongereza',
    'languageKinyarwanda': 'Ikinyarwanda',
    'patientTitle': 'Umurwayi mushya',
    'sex': 'Igitsina',
    'sexMale': 'Gabo',
    'sexFemale': 'Gore',
    'sexOther': 'Ikindi',
    'patientName': 'Amazina y’umurwayi',
    'patientNameHint': 'Amazina yombi y’umurwayi',
    'patientNameRequired': 'Amazina y’umurwayi arakenewe',
    'unknownPatient': 'Umurwayi utazwi',
    'yearsAbbrev': 'imyaka',
    'ageRange': 'Ikigero cy’imyaka',
    'selectAgeRange': 'Hitamo ikigero cy’imyaka',
    'location': 'Aho aherereye',
    'locationHint': 'Umudugudu / ivuriro / akarere',
    'locationRequired': 'Ahantu harakenewe',
    'skinType': 'Ubwoko bw’uruhu (Fitzpatrick)',
    'skinTypeHint': 'Kanda uruziga uhitemo ibara ry’uruhu risa cyane.',
    'fitz1': 'Ubwoko I — Uruhu rworoshye cyane; buri gihe rurahiye, ntirwijimira.',
    'fitz2': 'Ubwoko II — Uruhu rworoshye; akenshi rurahiye, rwijimira gake.',
    'fitz3': 'Ubwoko III — Uruhu ruciriritse; rimwe na rimwe rurahiye, rwijimira kimwe.',
    'fitz4': 'Ubwoko IV — Uruhu rw’ikigina; gake rurahiye, rwijimira byoroshye.',
    'fitz5': 'Ubwoko V — Uruhu rw’umukara woroheje; gake cyane rurahiye, rwijimira cyane.',
    'fitz6': 'Ubwoko VI — Uruhu rw’umukara winshi; ntirurahiye.',
    'consentAssessment':
        'Nemeza ko umurwayi yatanze uruhushya rw’amagambo n’urwanditse kuri iri '
            'suzuma no gufotora.',
    'consentPhoto':
        'Umurwayi yemeye ko afotorwa kandi ifoto ikabikwa kuri iyi telefone '
            'kubw’isuzuma.',
    'continueToCapture': 'Komeza gufata ifoto',
    'completeFields': 'Uzuza igitsina, ikigero cy’imyaka n’ubwoko bw’uruhu.',
    // Common
    'email': 'Imeyili',
    'password': 'Ijambobanga',
    'save': 'Bika',
    'emailRequired': 'Imeyili irakenewe',
    'passwordRequired': 'Ijambobanga rirakenewe',
    'validEmail': 'Andika imeyili yemewe',
    'passwordsNoMatch': 'Amagambobanga ntahuye',
    'regionDistrict': 'Intara / Akarere',
    'healthFacility': 'Ikigo nderabuzima',
    'minPasswordPrefix': 'Koresha byibura inyuguti',
    'characters': '',
    // Triage levels
    'triageUrgent': 'Kohereza byihutirwa',
    'triageMonitor': 'Gukurikirana',
    'triageTreatLocally': 'Kuvurira aho',
    // History
    'historyTitle': 'Amateka y’amasuzuma',
    'historyEmpty': 'Nta suzuma ryanditswe',
    'detailTitle': 'Amakuru y’isuzuma',
    'photoUnavailable': 'Ifoto ntiboneka',
    'chwNotes': 'Inyandiko za CHW',
    'confidenceWord': 'icyizere',
    // Result
    'triageResultTitle': 'Igisubizo cy’isuzuma',
    'analysing': 'Isuzuma rirakorwa...',
    'somethingWrong': 'Hari ikitagenze neza.',
    'retry': 'Ongera ugerageze',
    'retakePhoto': 'Ongera ufate ifoto',
    'backToHome': 'Subira ahabanza',
    'chwNotesOptional': 'Inyandiko za CHW (si itegeko)',
    'saveEncounter': 'Bika isuzuma',
    'saving': 'Birabikwa...',
    'encounterSaved': 'Isuzuma ryabitswe.',
    'noPatientSession': 'Nta murwayi uri muri sisitemu. Ntibishoboka kubika.',
    'noImage': 'Nta foto',
    'notSkinTitle': 'Ibi ntibisa n’uruhu',
    'notSkinMsg': 'Ifoto ntisa n’iy’uruhu. Fata ifoto isobanutse, yegereye '
        'ahagize ikibazo cy’uruhu, wongere ugerageze.',
    'healthyTitle': 'Uru ruhu rusa n’uruzima',
    'healthyMsg': 'Nta ndwara y’uruhu yabonetse. Niba umurwayi agifite '
        'impungenge, ongera ufate ifoto y’ahagize ikibazo cyangwa umwohereze '
        'kwa muganga.',
    'lowConfTitle': 'Icyizere ntigihagije',
    'lowConfMsgA': 'Porogaramu ntabwo yizeye iyi foto (munsi ya',
    'lowConfMsgB': 'by’icyizere). Ongera ufate ifoto isobanutse, ifite '
        'urumuri ruhagije, yegereye. Niba ukigira impungenge, ohereza umurwayi '
        'kwa muganga.',
    'retakeTitle': 'Ongera ufate ifoto',
    'retakeMsg': 'Fata ifoto isobanutse, yegereye, wongere ugerageze.',
    'inferenceWord': 'Isuzuma',
    'withinWord': 'muri',
    'overWord': 'hejuru ya',
    'targetWord': 'intego',
    // Login
    'loginHeading': 'Injira kugira ngo ukomeze',
    'enterEmail': 'Andika imeyili yawe',
    'enterPassword': 'Andika ijambobanga ryawe',
    'logIn': 'Injira',
    'signingIn': 'Kwinjira...',
    'pleaseWait': 'Tegereza gato...',
    'forgotPassword': 'Wibagiwe ijambobanga?',
    'continueWithGoogle': 'Komeza na Google',
    'newHealthWorker': 'Uri umujyanama mushya?',
    'register': 'Iyandikishe',
    'firstSignInInfo':
        'Kwinjira bwa mbere bisaba interineti. Nyuma yaho, porogaramu ikora '
            'nta interineti.',
    // Register
    'createAccount': 'Fungura konti',
    'creating': 'Birafungurwa...',
    'fullName': 'Amazina yombi',
    'yourNameHint': 'Amazina yawe',
    'enterName': 'Andika amazina yawe',
    'enterRegion': 'Andika intara yawe',
    'whereYouWorkHint': 'Aho ukorera',
    'enterFacility': 'Andika ikigo ukorera',
    'confirmPassword': 'Emeza ijambobanga',
    'accountCreated': 'Konti yafunguwe. Murakaza neza!',
    'alreadyHaveAccount': 'Nsanzwe mfite konti',
    'registerInternetInfo': 'Gufungura konti bisaba interineti iki gihe kimwe. '
        'Nyuma yaho, ushobora gukoresha porogaramu nta interineti.',
    // Forgot password
    'forgotTitle': 'Wibagiwe ijambobanga',
    'forgotIntro': 'Tuzakohereza imeyili irimo umuhora wo guhindura '
        'ijambobanga. Ibi bisaba interineti.',
    'enterYourEmail': 'Andika imeyili yawe',
    'sendResetLink': 'Ohereza umuhora',
    'sending': 'Birohererezwa...',
    'checkEmail': 'Reba imeyili yawe',
    'resetSentA': 'Twohereje umuhora wo guhindura ijambobanga kuri',
    'resetSentB': 'Uwufungure ushyireho ijambobanga rishya, hanyuma ugaruke '
        'winjire.',
    'backToLogin': 'Subira ku Kwinjira',
    // Profile
    'profileTitle': 'Umwirondoro wanjye',
    'profileOnlineNote': 'Guhindura konti bisaba interineti. Isuzuma rikora '
        'nta interineti.',
    'yourDetails': 'Amakuru yawe',
    'displayName': 'Izina rigaragara',
    'saveDetails': 'Bika amakuru',
    'detailsSaved': 'Amakuru yawe yabitswe.',
    'updateEmail': 'Hindura imeyili',
    'emailConfirmSent': 'Twohereje umuhora wo kwemeza kuri imeyili yawe nshya. '
        'Imeyili izahinduka umaze kuyifungura.',
    'changePasswordTitle': 'Hindura ijambobanga',
    'newPassword': 'Ijambobanga rishya',
    'confirmNewPassword': 'Emeza ijambobanga rishya',
    'changePasswordBtn': 'Hindura ijambobanga',
    'passwordChanged': 'Ijambobanga ryawe ryahinduwe.',
    // Camera
    'cameraTitle': 'Kamera',
    'cameraPermission': 'Uruhushya rwa kamera rurakenewe kugira ngo ufate '
        'ifoto y’ikibazo cy’uruhu.',
    'cameraStartFailed': 'Ntibyashobotse gutangiza kamera.',
    'noCamera': 'Nta kamera iri kuri iyi telefone.',
    'captureFailed': 'Gufata ifoto byanze',
    'goBack': 'Subira inyuma',
    'tryAgain': 'Ongera ugerageze',
    'openAppSettings': 'Fungura igenamiterere rya porogaramu',
    // Consent dialog
    'contributeCardLabel': 'Tanga ifoto y’uruhu rusanzwe',
    'contributeTitle': 'Tanga ifoto y’uruhu rusanzwe',
    'contributeIntro':
        'Fasha kunoza moderi ufotora uruhu rusanzwe (rudafite ikibazo). '
            'Hitamo ubwoko bw’uruhu (Fitzpatrick) n’aho ku mubiri, hanyuma ufate ifoto.',
    'bodyRegionLabel': 'Aho ku mubiri',
    'region_forearm': 'Okono y’ukuboko',
    'region_upper_arm': 'Ukuboko hejuru',
    'region_lower_leg': 'Ukuguru hasi',
    'region_torso': 'Igitereko',
    'region_face': 'Mu maso',
    'region_hand': 'Ikiganza',
    'region_neck': 'Ijosi',
    'contributionCameraGuidance': 'Uzuza ikazu n\'ahantu h\'umubiri — ukuboko cyangwa ukuguru kwose birakwiye',
    'contributionSavedTitle': 'Byabitswe — murakoze!',
    'contributionSavedMessageOnline':
        'Iyi foto irimo koherezwa nonaha. '
            'Ushobora gukomeza gufata izindi mu gihe kitameze.',
    'contributionSavedMessageOffline':
        'Nta interineti ufite — iyi foto izohereza ubwayo iyo umaze kugira '
            'interineti. Ushobora gukomeza gufata izindi mu gihe kitameze.',
    'viewMyContributions': 'Amafoto natanze',
    'myContributionsTitle': 'Amafoto natanze',
    'noContributionsYet': 'Ntabwo waratanga ifoto n’imwe.',
    'statusQueued': 'Birategereje — bizohereza iyo hari interineti',
    'statusUploaded': 'Byoherejwe',
    'consentTitle': 'Mbere yo gutangira',
    'consentAgree': 'Ndabyumva kandi ndemera',
    'consentPrototype':
        'Iyi porogaramu ni igerageza ry’ubushakashatsi, si igikoresho '
            'cy’ubuvuzi cyemewe.',
    'consentLegalIntro': 'Mukomeza, mwemeye',
    'consentLegalAnd': 'na',
    'legalSection': 'Amategeko',
    'privacyPolicyTitle': 'Politiki y’ibanga',
    'termsTitle': 'Amabwiriza y’ikoreshwa',
    'kinyarwandaSummaryLabel': 'Incamake mu Kinyarwanda',
    'fullTextLabel': 'Andika yuzuye (Icyongereza)',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'rw'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Wraps a framework localization delegate (Material/Widgets/Cupertino) so it
/// serves English data for locales it doesn't itself support — Flutter ships no
/// Kinyarwanda framework strings, so this keeps dialogs/date pickers working
/// (in English) while our own strings switch to Kinyarwanda.
class EnglishFallbackDelegate<T> extends LocalizationsDelegate<T> {
  const EnglishFallbackDelegate(this.inner);

  final LocalizationsDelegate<T> inner;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) =>
      inner.load(inner.isSupported(locale) ? locale : const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}
