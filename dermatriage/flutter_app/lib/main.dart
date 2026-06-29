import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/patient_provider.dart';
import 'presentation/providers/triage_provider.dart';
import 'presentation/widgets/common/consent_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase only needs the network for sign-in/registration/profile changes.
  // The session it persists is read from disk on later launches, so triage
  // keeps working offline.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AuthProvider.instance.init();
  runApp(const DermaTriage());
}

/// Root application widget.
class DermaTriage extends StatelessWidget {
  const DermaTriage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared auth session — same instance the router guard observes.
        ChangeNotifierProvider<AuthProvider>.value(
          value: AuthProvider.instance,
        ),
        ChangeNotifierProvider<TriageProvider>(
          create: (_) => TriageProvider()..init(),
        ),
        ChangeNotifierProvider<PatientProvider>(
          create: (_) => PatientProvider(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (_) => HistoryProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        builder: (BuildContext context, Widget? child) {
          return _ConsentGate(child: child ?? const SizedBox.shrink());
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
