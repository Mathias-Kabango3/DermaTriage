import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/profile_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/patient/patient_registration_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// Root navigator key — used to show app-level dialogs (e.g. consent) from
/// above the router's page navigator.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without an active session (the authentication gate).
const Set<String> _publicRoutes = <String>{
  '/login',
  '/register',
  '/forgot-password',
};

/// Application route table.
///
/// A [GoRouter.redirect] guard gates the triage features behind login: an
/// unauthenticated CHW is sent to `/login`, and an authenticated one is kept
/// out of the auth screens. The router refreshes whenever the shared
/// [AuthProvider] session changes.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: AuthProvider.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggedIn = AuthProvider.instance.isLoggedIn;
    final bool goingToPublic = _publicRoutes.contains(state.matchedLocation);

    if (!loggedIn && !goingToPublic) return '/login';
    if (loggedIn && goingToPublic) return '/';
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
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
