import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/auth/auth_service.dart';

/// Exposes the Firebase authentication session to the widget tree and the
/// GoRouter redirect guard.
///
/// Firebase Auth persists the signed-in user to disk, so on a cold start
/// [FirebaseAuth.currentUser] is restored **without** network access — the app
/// opens straight into the triage features offline. This provider simply
/// mirrors [FirebaseAuth.authStateChanges] so the router refreshes when the
/// CHW logs in or out.
class AuthProvider extends ChangeNotifier {
  AuthProvider._();

  /// Shared session used by the router guard and the provider tree.
  static final AuthProvider instance = AuthProvider._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _service = AuthService();

  StreamSubscription<User?>? _sub;

  /// Underlying service, used by the auth/profile screens.
  AuthService get service => _service;

  /// Subscribe to auth-state changes. Call once after Firebase is initialised.
  void init() {
    _sub ??= _auth.authStateChanges().listen((_) => notifyListeners());
  }

  /// The currently signed-in CHW, or null.
  User? get user => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// CHW display name, falling back to the email when unset.
  String? get displayName {
    final User? u = _auth.currentUser;
    final String? name = u?.displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    return u?.email;
  }

  String? get email => _auth.currentUser?.email;

  /// Sign out and return the app to the login gate.
  Future<void> logout() async {
    await _auth.signOut();
    // authStateChanges fires and notifies; nothing else to do.
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
