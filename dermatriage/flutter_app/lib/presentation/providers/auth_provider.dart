import 'package:flutter/foundation.dart';

import '../../services/auth/auth_service.dart';

/// Holds the in-memory authentication session (logged-in flag + current
/// username) and exposes the [AuthService] for the auth screens.
///
/// A single shared [instance] is used so the GoRouter redirect guard and the
/// widget tree observe the same session state. The session lives only in
/// memory: closing the app signs the CHW out.
class AuthProvider extends ChangeNotifier {
  AuthProvider._();

  /// Shared session used by the router guard and the provider tree.
  static final AuthProvider instance = AuthProvider._();

  final AuthService _service = AuthService();

  /// Underlying service, for flows that don't change session state
  /// (register, forgot-password, change-password).
  AuthService get service => _service;

  bool _isLoggedIn = false;
  String? _currentUsername;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUsername => _currentUsername;

  /// Attempt to log in. On success the session is updated and listeners
  /// (including the router) are notified. Returns true on success.
  Future<bool> login(String username, String password) async {
    final bool ok = await _service.login(username, password);
    if (ok) {
      _isLoggedIn = true;
      _currentUsername = username.trim();
      notifyListeners();
    }
    return ok;
  }

  /// Clear the session and return the app to the login gate.
  void logout() {
    _isLoggedIn = false;
    _currentUsername = null;
    notifyListeners();
  }
}
