import 'package:dermatriage/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strings differ between en and rw', () {
    final en = AppLocalizations(const Locale('en'));
    final rw = AppLocalizations(const Locale('rw'));
    expect(en.navHome, 'Home');
    expect(rw.navHome, 'Ahabanza');
    expect(en.homeStartTriage, 'Start New Triage');
    expect(rw.homeStartTriage, 'Tangira isuzuma rishya');
    expect(en.signedInAs('Mathias'), 'Signed in as Mathias');
    expect(rw.signedInAs('Mathias'), 'Winjiye nka Mathias');
    // Patient screen strings translated (and not falling back to the key/English)
    expect(rw.patientTitle, 'Umurwayi mushya');
    expect(rw.sexLabel('M'), 'Gabo');
    expect(rw.sexLabel('Other'), 'Ikindi');
    expect(rw.fitzpatrickDescription(3), startsWith('Ubwoko III'));
    expect(rw.consentPhoto, isNot(en.consentPhoto));
    expect(rw.continueToCapture, 'Komeza gufata ifoto');
    // Spot-check one string from each newly localized screen; each must be
    // translated (differ from English) and not fall back to the raw key.
    for (final s in <String>[
      rw.historyTitle, rw.triageLabel('MONITOR'), rw.notSkinTitle,
      rw.loginHeading, rw.createAccount, rw.forgotTitle, rw.profileTitle,
      rw.saveEncounter, rw.cameraTitle, rw.consentAgree, rw.settings,
      rw.contributeCardLabel, rw.contributeTitle, rw.contributeIntro,
      rw.bodyRegionLabel, rw.contributionCameraGuidance,
      rw.contributionSavedTitle, rw.contributionSavedMessageOnline,
      rw.contributionSavedMessageOffline,
      rw.viewMyContributions, rw.myContributionsTitle,
      rw.noContributionsYet, rw.statusQueued, rw.statusUploaded,
    ]) {
      expect(s, isNotEmpty);
      expect(s.contains(RegExp(r'^[a-z][a-zA-Z]+\$')), isFalse,
          reason: 'looks like an untranslated key: \$s');
    }
    expect(rw.historyTitle, isNot(en.historyTitle));
    expect(rw.loginHeading, isNot(en.loginHeading));
    expect(rw.triageLabel('URGENT_REFERRAL'), isNot(en.triageLabel('URGENT_REFERRAL')));
    expect(rw.lowConfMsg(50), contains('50%'));
    // Every body region slug must resolve to a translated (non-key) name in
    // both languages — these are shown as ChoiceChip labels on the
    // contribution metadata screen.
    for (final id in <String>[
      'forearm', 'upper_arm', 'lower_leg', 'torso', 'face', 'hand', 'neck',
    ]) {
      expect(en.bodyRegionName(id), isNotEmpty);
      expect(rw.bodyRegionName(id), isNotEmpty);
      expect(rw.bodyRegionName(id), isNot(en.bodyRegionName(id)));
    }
  });

  testWidgets('delegate resolves Kinyarwanda through MaterialApp', (t) async {
    late AppLocalizations resolved;
    await t.pumpWidget(MaterialApp(
      locale: const Locale('rw'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        EnglishFallbackDelegate<MaterialLocalizations>(
            GlobalMaterialLocalizations.delegate),
        EnglishFallbackDelegate<WidgetsLocalizations>(
            GlobalWidgetsLocalizations.delegate),
        EnglishFallbackDelegate<CupertinoLocalizations>(
            GlobalCupertinoLocalizations.delegate),
      ],
      home: Builder(builder: (ctx) {
        resolved = AppLocalizations.of(ctx);
        return Scaffold(body: Text(resolved.homeViewHistory));
      }),
    ));
    await t.pump();
    expect(resolved.locale.languageCode, 'rw');
    expect(find.text('Reba amateka'), findsOneWidget); // "View History" in rw
  });
}
