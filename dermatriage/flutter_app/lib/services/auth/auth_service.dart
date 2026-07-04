import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Online authentication for CHW accounts, backed by Firebase Auth.
///
/// Authentication happens **online** so the project owner can see how many
/// CHWs are registered (Firebase console) and so accounts can be managed
/// properly. Firebase Auth persists the signed-in session to disk by default,
/// so after the first online sign-in the app keeps working **offline** for
/// triage — only sign-in, registration and profile changes need the internet.
///
/// Extra profile fields that Firebase Auth cannot hold (region, facility) live
/// in a `chws/{uid}` Cloud Firestore document.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  /// Sentinel returned by [signInWithGoogle] when the user dismisses the
  /// Google account chooser (not an error — the UI should just do nothing).
  static const String cancelled = '__cancelled__';

  /// Firestore collection of CHW profile documents.
  CollectionReference<Map<String, dynamic>> get _chws =>
      _db.collection('chws');

  /// Sign in with a Google account and link it to Firebase Auth.
  ///
  /// Uses Firebase's web-based OAuth flow ([FirebaseAuth.signInWithProvider]),
  /// which opens a browser tab instead of relying on Google Play Services — so
  /// it also works on devices without GMS (e.g. Huawei).
  ///
  /// Returns null on success, [cancelled] if the CHW dismissed the browser, or
  /// a friendly error message otherwise. Region/facility are left blank for
  /// Google sign-ups; the CHW can fill them in on the Profile screen.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      final UserCredential cred = await _auth.signInWithProvider(provider);
      final User user = cred.user!;

      // Create/merge the CHW profile so the owner can see the account. Only
      // fill fields we actually have from Google (don't clobber existing ones).
      await _chws.doc(user.uid).set(<String, dynamic>{
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'signInMethod': 'google',
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      // The user closing the browser surfaces as one of these codes.
      if (e.code == 'canceled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'user-cancelled') {
        return cancelled;
      }
      return _authMessage(e);
    } catch (_) {
      return 'Google sign-in did not complete. Please try again.';
    }
  }

  /// Register a new CHW with email/password and store their profile.
  ///
  /// Returns a CHW-friendly error message on failure, or null on success.
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String region,
    required String facility,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _chws.doc(user.uid).set(<String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'region': region.trim(),
        'facility': facility.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Something went wrong while creating your account. '
          'Please try again.';
    }
  }

  /// Sign a CHW in. Returns null on success or a friendly error message.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Something went wrong while signing in. Please try again.';
    }
  }

  /// Sign the current CHW out (clears the locally persisted session).
  Future<void> signOut() => _auth.signOut();

  /// Send a password-reset email (requires internet).
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Could not send the reset email. Please try again.';
    }
  }

  /// Read the current CHW's extra profile fields (region/facility) from
  /// Firestore. Works offline from cache once fetched. Returns an empty map
  /// if there is no profile document yet.
  Future<Map<String, dynamic>> loadProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return <String, dynamic>{};
    try {
      final snap = await _chws.doc(user.uid).get();
      return snap.data() ?? <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Update the CHW's display name and Firestore profile fields
  /// (region/facility). Returns null on success or a friendly error message.
  Future<String?> updateProfile({
    required String name,
    required String region,
    required String facility,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';
    try {
      await user.updateDisplayName(name.trim());
      await _chws.doc(user.uid).set(<String, dynamic>{
        'name': name.trim(),
        'region': region.trim(),
        'facility': facility.trim(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Could not save your profile. Please check your internet '
          'connection and try again.';
    }
  }

  /// Start an email change. Firebase sends a confirmation link to the new
  /// address; the email only changes once the CHW taps it. Requires internet.
  Future<String?> updateEmail(String newEmail) async {
    final User? user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';
    try {
      await user.verifyBeforeUpdateEmail(newEmail.trim());
      await _chws.doc(user.uid).set(
        <String, dynamic>{'email': newEmail.trim()},
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Could not update your email. Please try again.';
    }
  }

  /// Change the signed-in CHW's password. Requires internet, and Firebase may
  /// require a recent sign-in (handled with a friendly message).
  Future<String?> updatePassword(String newPassword) async {
    final User? user = _auth.currentUser;
    if (user == null) return 'You are not signed in.';
    try {
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (_) {
      return 'Could not change your password. Please try again.';
    }
  }

  /// Map Firebase error codes to short, non-technical messages for CHWs.
  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. The first sign-in or registration '
            'needs internet — after that, the app works offline.';
      case 'email-already-in-use':
        return 'An account with this email already exists. '
            'Please log in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. '
            'Please contact your supervisor.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'requires-recent-login':
        return 'For your security, please log out and log in again before '
            'making this change.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. '
            'Please contact your supervisor.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
