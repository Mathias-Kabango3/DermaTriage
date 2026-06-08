import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/patient_provider.dart';
import 'presentation/providers/triage_provider.dart';

void main() {
  runApp(const DermaTriage());
}

/// Root application widget.
class DermaTriage extends StatelessWidget {
  const DermaTriage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ),
    );
  }
}
