import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/contribution_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/patient_provider.dart';
import 'presentation/providers/triage_provider.dart';
import 'presentation/widgets/common/consent_dialog.dart';
import 'services/contribution/contribution_upload_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase only needs the network for sign-in/registration/profile changes.
  // The session it persists is read from disk on later launches, so triage
  // keeps working offline.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AuthProvider.instance.init();
  // Retry any healthy-skin contributions still queued from a previous
  // offline session, then keep retrying whenever connectivity returns.
  ContributionUploadService.instance.startAutoSync();
  // Restore the saved language before the first frame so the app opens in it.
  final LocaleProvider localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(DermaTriage(localeProvider: localeProvider));
}

/// Root application widget.
class DermaTriage extends StatelessWidget {
  final LocaleProvider localeProvider;

  const DermaTriage({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared auth session — same instance the router guard observes.
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider.instance,
        ),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<TriageProvider>(
          create: (_) => TriageProvider()..init(),
        ),
        ChangeNotifierProvider<PatientProvider>(
          create: (_) => PatientProvider(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (_) => HistoryProvider(),
        ),
        ChangeNotifierProvider<ContributionProvider>(
          create: (_) => ContributionProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (BuildContext context, LocaleProvider locale, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: AppTheme.light,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            // Language: English + Kinyarwanda. Framework strings fall back to
            // English for Kinyarwanda (Flutter ships no `rw` framework data).
            locale: locale.locale,
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
            builder: (BuildContext context, Widget? child) {
              return _ConsentGate(child: child ?? const SizedBox.shrink());
            },
          );
        },
      ),
    );
  }
}

/// Shows the first-launch [ConsentDialog] once, then renders the app.
class _ConsentGate extends StatefulWidget {
  final Widget child;

  const _ConsentGate({required this.child});

  @override
  State<_ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<_ConsentGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowConsent());
  }

  Future<void> _maybeShowConsent() async {
    final bool accepted = await ConsentDialog.hasAccepted();
    if (accepted || !mounted) return;
    // Use the router's navigator context so the dialog sits inside a Navigator.
    final BuildContext? navContext = rootNavigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      await ConsentDialog.show(navContext);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
