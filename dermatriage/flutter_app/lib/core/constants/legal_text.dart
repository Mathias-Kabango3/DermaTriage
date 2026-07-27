/// Full legal text for the Privacy Policy and Terms of Use.
///
/// Kept separate from [AppConstants] because it is long. English is the
/// authoritative text; the Kinyarwanda fields are a short first-pass summary
/// only and should be reviewed by a native/legal speaker before release —
/// see [[feedback-report-diagrams]]-style notes in project memory.
class LegalText {
  LegalText._();

  static const String lastUpdated = '23 July 2026';

  static const String privacyPolicyEn = '''
Last updated: $lastUpdated

DermaTriage is an offline-first application. This policy explains what information the app collects, where it is stored, and your rights over it.

1. Information We Collect

CHW account (you): When you register, we collect your name, email address, region/district, and health facility. This identifies you as a health worker and lets you sign in.

Patient encounter data: When you run a triage, the app records the patient's name, approximate age range, sex, location, Fitzpatrick skin type, the captured photo, the model's prediction and confidence, the triage category, and any notes you add. The patient's name is stored only on this device (see below) so you can recognise them in the encounter history — it is never uploaded anywhere.

2. Where Your Data Is Stored

On this device only: All patient and encounter data — including every photograph — is stored locally on this device in an offline database. It is never uploaded to any server, and the on-device AI model runs without an internet connection.

In the cloud (Firebase and Cloudinary): Your CHW account details (name, email, region, facility) are sent to Firebase (a Google service) so you can sign in and recover your password. If you choose to use the separate, optional "Contribute Healthy Skin Photo" feature, the photo you submit and its metadata (Fitzpatrick type, body region, your CHW id, facility, capture time) are uploaded to Cloudinary (an image-hosting service) and Firestore (Google), so the research team can use it to improve the AI model. Patient encounter data is never included in either of these — only your CHW account and anything you explicitly submit as a contribution leave this device.

Cross-border storage and your consent: Firebase and Cloudinary store data outside Rwanda. Under Rwanda's Law N° 058/2021 relating to the protection of personal data and privacy, storing personal data outside Rwanda requires either your consent or authorisation from the National Cyber Security Authority (NCSA). We rely on your consent: by accepting this policy (at first launch, or when registering your CHW account) you consent to your CHW account data, and any healthy-skin contribution you choose to submit, being stored outside Rwanda on Firebase and Cloudinary for the purposes described above. Patient encounter data is unaffected — it never leaves this device, so no cross-border transfer of patient data occurs.

3. What We Do Not Do

We do not sell or share your data with third parties for marketing. We do not run analytics or advertising trackers. We do not upload patient photos to any server.

4. Data Retention & Deletion

Patient and encounter data remains on the device until you delete it. You can permanently erase all locally stored patient and encounter data at any time from Settings → Reset All Data. To delete your CHW account itself, contact the project maintainer (see the app's README).

5. Third Parties

The app uses Firebase Authentication and Cloud Firestore (Google) to manage CHW accounts and, if you choose to contribute a healthy-skin photo, to store its metadata. Photos submitted through the contribution feature are hosted on Cloudinary. Google's and Cloudinary's own privacy policies govern how each processes that data.

6. Children and Vulnerable Persons

Patients photographed using this app are not users of the app and do not create accounts. Community health workers must obtain the patient's (or guardian's) informed consent before capturing any image, as described in the in-app consent notice.

7. Your Rights

You may access, export (via the app), or delete the patient and encounter data on your device at any time. Because this data is stored locally, you are in direct control of it.

8. Changes to This Policy

We may update this policy as the app evolves. The "Last updated" date above reflects the most recent revision.

9. Contact

Questions about this policy can be directed to the project maintainer, as listed in this app's README.
''';

  /// First-pass Kinyarwanda summary — not a full translation. Needs review.
  static const String privacyPolicyRwSummary =
      'Incamake: Amakuru y’abarwayi (ifoto, imyaka, aho batuye, ubwoko '
      'bw’uruhu, n’amazina) abikwa gusa kuri iyi telefone, ntabwo yoherezwa ku '
      'rubuga rwa interineti. Ni amakuru y’umujyanama gusa (amazina, imeyili, '
      'akarere, ikigo) yoherezwa kuri Firebase kugira ngo yinjire muri konti '
      'ye; niba wemeye gutanga ifoto y’uruhu rusanzwe (feature yihitiyemo), '
      'iyo foto yoherezwa kuri Cloudinary na Firestore (hanze ya Rwanda). '
      'Itegeko ry’u Rwanda N° 058/2021 risaba uruhushya rwawe cyangwa '
      'urw’Ikigo cy’Igihugu gishinzwe Umutekano w’Ikoranabuhanga (NCSA) '
      'kugira ngo amakuru abikwe hanze y’igihugu — twemera uruhushya rwawe '
      'igihe wemeye iri tegeko. Ushobora gusiba amakuru y’abarwayi igihe '
      'cyose muri Igenamiterere → Siba amakuru yose. Reba andika yuzuye mu '
      'Cyongereza hepfo.';

  static const String termsOfUseEn = '''
Last updated: $lastUpdated

By installing or using DermaTriage, you agree to these Terms of Use.

1. Purpose

DermaTriage is a research prototype developed as a BSc Software Engineering capstone project. It is designed to assist trained community health workers with preliminary skin-condition triage. It is NOT an approved medical device and must not be used as a substitute for professional medical diagnosis or treatment.

2. Licence

You are granted a limited, non-exclusive, non-transferable licence to use this app for its intended purpose (community health triage support and academic evaluation). You may not resell, sublicense, or redistribute the app or its underlying model without permission.

3. No Warranty

The app is provided "as is", without warranty of any kind, express or implied. The developer does not guarantee the accuracy, completeness, or reliability of any triage suggestion.

4. Limitation of Liability

To the fullest extent permitted by law, the developer is not liable for any harm, loss, or damage arising from reliance on this app's output. All clinical decisions remain the sole responsibility of the health worker and supervising clinicians.

5. User Responsibilities

You agree to: obtain informed consent before capturing any patient image; exercise independent clinical judgement; refer patients to a qualified clinician when in doubt or as required by the in-app guidance; and use the app only for its intended purpose.

6. Data

Your use of the app is also governed by the DermaTriage Privacy Policy, which explains what data is collected and how it is stored.

7. Changes

These terms may be updated as the app evolves. Continued use after an update constitutes acceptance of the revised terms.

8. Governing Context

This app is provided as an academic capstone project of the African Leadership University and is not a commercial medical product.
''';

  /// First-pass Kinyarwanda summary — not a full translation. Needs review.
  static const String termsOfUseRwSummary =
      'Incamake: DermaTriage ni igerageza ry’ubushakashatsi, si igikoresho '
      'cy’ubuvuzi cyemewe, kandi ntabwo isimbura umuganga. Ukoresha '
      'porogaramu wemeye ko ufite inshingano zo gufata ibyemezo '
      'by’ubuvuzi wite ku bushobozi bwawe, gusaba uruhushya rw’umurwayi '
      'mbere yo gufotora, no kohereza umurwayi kwa muganga igihe '
      'bikenewe. Porogaramu itangwa uko iri, nta cyizigirwa cy’uko '
      'itazakosa. Reba andika yuzuye mu Cyongereza hepfo.';
}
