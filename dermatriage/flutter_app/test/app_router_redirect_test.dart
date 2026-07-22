// Regression test for a real bug: legal pages were lumped into the same
// "public routes" set used to bounce a signed-in CHW back to '/'. That meant
// tapping Privacy Policy / Terms of Use from Settings (only reachable while
// logged in) redirected straight back to the home screen instead of opening
// the page. resolveRedirect() is a pure extraction of the router's decision
// so this is testable without a real Firebase session.

import 'package:dermatriage/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('logged out', () {
    test('protected route redirects to /login', () {
      expect(resolveRedirect(loggedIn: false, location: '/'), '/login');
      expect(
          resolveRedirect(loggedIn: false, location: '/settings'), '/login');
    });

    test('auth screens stay put', () {
      expect(resolveRedirect(loggedIn: false, location: '/login'), null);
      expect(resolveRedirect(loggedIn: false, location: '/register'), null);
      expect(
          resolveRedirect(loggedIn: false, location: '/forgot-password'),
          null);
    });

    test('legal pages are reachable pre-login (consent dialog)', () {
      expect(
          resolveRedirect(loggedIn: false, location: '/legal/privacy'), null);
      expect(resolveRedirect(loggedIn: false, location: '/legal/terms'), null);
    });
  });

  group('logged in', () {
    test('auth screens bounce back to home', () {
      expect(resolveRedirect(loggedIn: true, location: '/login'), '/');
      expect(resolveRedirect(loggedIn: true, location: '/register'), '/');
      expect(
          resolveRedirect(loggedIn: true, location: '/forgot-password'), '/');
    });

    test('legal pages stay open — the bug this test pins', () {
      expect(resolveRedirect(loggedIn: true, location: '/legal/privacy'),
          null);
      expect(
          resolveRedirect(loggedIn: true, location: '/legal/terms'), null);
    });

    test('normal app routes are unaffected', () {
      expect(resolveRedirect(loggedIn: true, location: '/'), null);
      expect(resolveRedirect(loggedIn: true, location: '/settings'), null);
      expect(resolveRedirect(loggedIn: true, location: '/history'), null);
    });
  });
}
