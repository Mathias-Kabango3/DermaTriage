// Verifies the legal pages render and the consent dialog's links actually
// navigate to them — this is the part that's easy to wire wrong (dangling
// GestureDetector, wrong route, missing import).

import 'package:dermatriage/core/constants/legal_text.dart';
import 'package:dermatriage/l10n/app_localizations.dart';
import 'package:dermatriage/presentation/screens/legal/legal_screen.dart';
import 'package:dermatriage/presentation/widgets/common/consent_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('LegalScreen shows title, Kinyarwanda summary and English body',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const LegalScreen(
      title: 'Privacy Policy',
      bodyEn: LegalText.privacyPolicyEn,
      rwSummary: LegalText.privacyPolicyRwSummary,
    )));
    // AppLocalizations.delegate.load() is async, so localized text isn't in
    // the tree until the following microtask/frame resolves.
    await tester.pump();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Kinyarwanda summary'), findsOneWidget);
    expect(find.text('Full text (English)'), findsOneWidget);
    // A distinctive sentence from the English body must actually be present.
    expect(
      find.textContaining('never uploaded to any server'),
      findsOneWidget,
    );
  });

  testWidgets('consent dialog Privacy Policy link opens the Privacy Policy',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => ConsentDialog.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    // Flush the async AppLocalizations.delegate.load() before interacting.
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The dialog's disclaimer body can push the link below the fold on the
    // default test surface; scroll it into view before tapping.
    await tester.ensureVisible(find.text('Privacy Policy').last);
    expect(find.text('Before you begin'), findsOneWidget);

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    // The legal screen pushed on top; its AppBar title proves navigation
    // actually happened rather than silently no-oping.
    expect(find.widgetWithText(AppBar, 'Privacy Policy'), findsOneWidget);
    expect(find.textContaining('never uploaded to any server'),
        findsOneWidget);
  });

  testWidgets('consent dialog Terms of Use link opens the Terms',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (BuildContext context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => ConsentDialog.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    // Flush the async AppLocalizations.delegate.load() before interacting.
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The dialog's disclaimer body can push the link below the fold on the
    // default test surface; scroll it into view before tapping.
    await tester.ensureVisible(find.text('Terms of Use'));

    await tester.tap(find.text('Terms of Use'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Terms of Use'), findsOneWidget);
    expect(find.textContaining('NOT an approved medical device'),
        findsOneWidget);
  });
}
