import 'package:go_router/go_router.dart';

import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/patient/patient_registration_screen.dart';
import '../../presentation/screens/result_screen.dart';
import '../../presentation/screens/settings_screen.dart';

/// Application route table.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/patient/register',
      name: 'patientRegister',
      builder: (context, state) => const PatientRegistrationScreen(),
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
