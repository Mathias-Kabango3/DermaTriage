import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/profile_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/camera/camera_screen.dart';
import '../../presentation/screens/contribution/contribution_metadata_screen.dart';
import '../../presentation/screens/contribution/my_contributions_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/legal/legal_screen.dart';
import '../../presentation/screens/patient/patient_registration_screen.dart';
import '../../presentation/screens/result/result_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../constants/legal_text.dart';

/// Root navigator key — used to show app-level dialogs (e.g. consent) from
/// above the router's page navigator.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes reachable without an active session.
///
/// The legal pages are here too so the first-launch consent dialog — shown
/// before any sign-in — can link to them.
const Set<String> _unauthenticatedRoutes = <String>{
  '/login',
  '/register',
  '/forgot-password',
  '/legal/privacy',
  '/legal/terms',
};

/// Of those, the auth screens a signed-in CHW should be bounced away from
/// (back to `/`) if they land on them. Legal pages are excluded on purpose —
/// unlike login/register, a signed-in CHW must still be able to open them
/// (e.g. from Settings), so they are reachable both logged in and out.
const Set<String> _authOnlyRoutes = <String>{
  '/login',
  '/register',
  '/forgot-password',
};

/// Pure routing decision, extracted from [GoRouter.redirect] so it can be
/// unit-tested without a real Firebase session (see
/// test/app_router_redirect_test.dart).
String? resolveRedirect({required bool loggedIn, required String location}) {
  if (!loggedIn && !_unauthenticatedRoutes.contains(location)) return '/login';
  if (loggedIn && _authOnlyRoutes.contains(location)) return '/';
  return null;
}

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
  redirect: (BuildContext context, GoRouterState state) => resolveRedirect(
    loggedIn: AuthProvider.instance.isLoggedIn,
    location: state.matchedLocation,
  ),
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
      path: '/contribute',
      name: 'contribute',
      builder: (context, state) => const ContributionMetadataScreen(),
    ),
    GoRoute(
      path: '/contributions',
      name: 'myContributions',
      builder: (context, state) => const MyContributionsScreen(),
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
    GoRoute(
      path: '/legal/privacy',
      name: 'privacyPolicy',
      builder: (context, state) => LegalScreen(
        title: AppLocalizations.of(context).privacyPolicyTitle,
        bodyEn: LegalText.privacyPolicyEn,
        rwSummary: LegalText.privacyPolicyRwSummary,
      ),
    ),
    GoRoute(
      path: '/legal/terms',
      name: 'termsOfUse',
      builder: (context, state) => LegalScreen(
        title: AppLocalizations.of(context).termsTitle,
        bodyEn: LegalText.termsOfUseEn,
        rwSummary: LegalText.termsOfUseRwSummary,
      ),
    ),
  ],
);
