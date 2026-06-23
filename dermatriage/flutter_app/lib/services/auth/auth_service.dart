import 'package:bcrypt/bcrypt.dart';

import '../../data/datasources/local/user_dao.dart';
import '../../data/models/app_user.dart';

/// Offline authentication logic for CHW accounts.
///
/// All operations run entirely on-device against the local SQLite database.
/// Passwords and security answers are only ever persisted as bcrypt hashes;
/// the raw values are never stored, so a forgotten password can be *reset*
/// (via the security question) but never *retrieved*.
class AuthService {
  final UserDao _dao;

  AuthService({UserDao? dao}) : _dao = dao ?? UserDao();

  /// Register a new CHW.
  ///
  /// Returns a human-friendly error message on failure, or null on success.
  Future<String?> register(
    String username,
    String password,
    String securityQuestion,
    String securityAnswer,
  ) async {
    final String name = username.trim();
    if (name.isEmpty) return 'Please enter a username.';
    if (password.isEmpty) return 'Please enter a password.';
    if (securityAnswer.trim().isEmpty) {
      return 'Please answer your security question.';
    }

    final AppUser? existing = await _dao.getByUsername(name);
    if (existing != null) {
      return 'That username is already taken. Please choose another.';
    }

    final AppUser user = AppUser(
      username: name,
      passwordHash: _hash(password),
      securityQuestion: securityQuestion,
      securityAnswerHash: _hash(_normalizeAnswer(securityAnswer)),
      createdAt: DateTime.now(),
    );
    await _dao.insertUser(user);
    return null;
  }

  /// Verify a username/password pair. Returns true on success.
  Future<bool> login(String username, String password) async {
    final AppUser? user = await _dao.getByUsername(username.trim());
    if (user == null) return false;
    return BCrypt.checkpw(password, user.passwordHash);
  }

  /// Change the password for a user who knows their current one.
  ///
  /// Verifies [oldPassword] first. Returns an error message on failure, or
  /// null on success.
  Future<String?> changePassword(
    String username,
    String oldPassword,
    String newPassword,
  ) async {
    final AppUser? user = await _dao.getByUsername(username.trim());
    if (user == null) return 'Account not found.';
    if (!BCrypt.checkpw(oldPassword, user.passwordHash)) {
      return 'Your current password is incorrect.';
    }
    await _dao.updatePasswordHash(user.username, _hash(newPassword));
    return null;
  }

  /// Return the stored security question for [username], or null if there is
  /// no such account. Used by the offline "forgot password" flow.
  Future<String?> getSecurityQuestion(String username) async {
    final AppUser? user = await _dao.getByUsername(username.trim());
    return user?.securityQuestion;
  }

  /// Offline password recovery: verify the security answer, then set a new
  /// password. Returns an error message on failure, or null on success.
  Future<String?> resetPasswordWithSecurityAnswer(
    String username,
    String securityAnswer,
    String newPassword,
  ) async {
    final AppUser? user = await _dao.getByUsername(username.trim());
    if (user == null) return 'No account found with that username.';
    if (!BCrypt.checkpw(
      _normalizeAnswer(securityAnswer),
      user.securityAnswerHash,
    )) {
      return 'That answer does not match. Please try again.';
    }
    await _dao.updatePasswordHash(user.username, _hash(newPassword));
    return null;
  }

  /// Whether at least one CHW account exists on this device.
  Future<bool> hasAnyUser() async => (await _dao.count()) > 0;

  /// Hash a secret with a freshly generated bcrypt salt.
  String _hash(String value) => BCrypt.hashpw(value, BCrypt.gensalt());

  /// Normalise a security answer so matching is case- and
  /// whitespace-insensitive.
  String _normalizeAnswer(String answer) => answer.trim().toLowerCase();
}
