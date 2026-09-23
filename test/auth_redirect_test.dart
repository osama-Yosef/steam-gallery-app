import 'package:flutter_test/flutter_test.dart';
import 'package:steam_gallery_app/core/router/auth_redirect.dart';
import 'package:steam_gallery_app/core/router/route_names.dart';
import 'package:steam_gallery_app/features/auth/data/models/app_user.dart';

AppUser _user({
  AppRole role = AppRole.customer,
  bool active = true,
  bool verified = true,
  String? email = 'test@example.com',
}) => AppUser(
  id: 'u1',
  role: role,
  fullName: 'Test',
  phone: '201012345678',
  email: email,
  isActive: active,
  phoneVerifiedAt: verified ? DateTime(2026) : null,
);

String? _redirect(
  String location, {
  bool hasSession = true,
  ProfileStatus status = ProfileStatus.ready,
  AppUser? user,
  bool requireVerifiedPhone = false,
  bool recovery = false,
}) => resolveAuthRedirect(
  location: location,
  hasSession: hasSession,
  profileStatus: status,
  user: user,
  requireVerifiedPhone: requireVerifiedPhone,
  passwordRecoveryInProgress: recovery,
);

void main() {
  group('signed out', () {
    test('public auth screens are reachable', () {
      for (final loc in [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
        Routes.verifyOtp,
      ]) {
        expect(_redirect(loc, hasSession: false), isNull, reason: loc);
      }
    });

    test('everything else goes to login', () {
      for (final loc in [
        Routes.splash,
        Routes.customerHome,
        Routes.adminHome,
        Routes.resetPassword,
        Routes.verifyPhone,
        Routes.addEmail,
      ]) {
        expect(_redirect(loc, hasSession: false), Routes.login, reason: loc);
      }
    });

    test('a leftover recovery flag grants nothing without a session', () {
      expect(
        _redirect(Routes.resetPassword, hasSession: false, recovery: true),
        Routes.login,
      );
    });
  });

  group('password recovery', () {
    test('holds the recovered session on the new-password screen', () {
      expect(
        _redirect(Routes.verifyOtp, user: _user(), recovery: true),
        Routes.resetPassword,
      );
      expect(
        _redirect(Routes.customerHome, user: _user(), recovery: true),
        Routes.resetPassword,
      );
      expect(
        _redirect(Routes.resetPassword, user: _user(), recovery: true),
        isNull,
      );
    });

    test('once finished, the new-password screen sends the user home', () {
      expect(
        _redirect(Routes.resetPassword, user: _user()),
        Routes.customerHome,
      );
    });
  });

  group('profile loading', () {
    test('first load waits on splash', () {
      expect(
        _redirect(Routes.login, status: ProfileStatus.loading),
        Routes.splash,
      );
      expect(_redirect(Routes.splash, status: ProfileStatus.loading), isNull);
    });

    test('a row not provisioned yet waits on splash', () {
      expect(
        _redirect(Routes.verifyOtp, status: ProfileStatus.missing),
        Routes.splash,
      );
    });

    test('a failed load goes back to login', () {
      expect(
        _redirect(Routes.splash, status: ProfileStatus.error),
        Routes.login,
      );
    });
  });

  group('account state', () {
    test('a deactivated account only sees the suspended screen', () {
      final suspended = _user(role: AppRole.admin, active: false);
      expect(
        _redirect(Routes.adminHome, user: suspended),
        Routes.accountSuspended,
      );
      expect(_redirect(Routes.accountSuspended, user: suspended), isNull);
    });

    test('unverified customer is held on verify-phone when required', () {
      final unverified = _user(verified: false);
      expect(
        _redirect(
          Routes.customerCart,
          user: unverified,
          requireVerifiedPhone: true,
        ),
        Routes.verifyPhone,
      );
      expect(
        _redirect(
          Routes.verifyPhone,
          user: unverified,
          requireVerifiedPhone: true,
        ),
        isNull,
      );
    });

    test('unverified customer is not held when not required', () {
      expect(
        _redirect(Routes.customerCart, user: _user(verified: false)),
        isNull,
      );
    });

    test('staff are never held for phone verification', () {
      for (final role in [AppRole.admin, AppRole.technician]) {
        expect(
          _redirect(
            homeFor(role),
            user: _user(role: role, verified: false),
            requireVerifiedPhone: true,
          ),
          isNull,
          reason: role.name,
        );
      }
    });

    test('verification done: verify-phone sends the customer home', () {
      expect(
        _redirect(
          Routes.verifyPhone,
          user: _user(),
          requireVerifiedPhone: true,
        ),
        Routes.customerHome,
      );
    });

    test('a customer with no email (pre-0070 account) is held on add-email', () {
      final noEmail = _user(email: null);
      expect(_redirect(Routes.customerCart, user: noEmail), Routes.addEmail);
      expect(_redirect(Routes.addEmail, user: noEmail), isNull);
    });

    test('adding the email sends the customer home', () {
      expect(_redirect(Routes.addEmail, user: _user()), Routes.customerHome);
    });

    test('staff are never held for missing email', () {
      for (final role in [AppRole.admin, AppRole.technician, AppRole.sales]) {
        expect(
          _redirect(homeFor(role), user: _user(role: role, email: null)),
          isNull,
          reason: role.name,
        );
      }
    });
  });

  group('role areas', () {
    test('signed-in users on auth screens go to their own home', () {
      expect(
        _redirect(Routes.login, user: _user(role: AppRole.admin)),
        Routes.adminHome,
      );
      expect(
        _redirect(Routes.register, user: _user(role: AppRole.technician)),
        Routes.technicianHome,
      );
    });

    test('a customer typing an admin or technician URL is sent home', () {
      expect(_redirect('/admin/users', user: _user()), Routes.customerHome);
      expect(_redirect('/technician/bag', user: _user()), Routes.customerHome);
    });

    test('a technician cannot enter the admin area', () {
      expect(
        _redirect('/admin/cashbox', user: _user(role: AppRole.technician)),
        Routes.technicianHome,
      );
    });

    test('each role stays in its own area', () {
      expect(_redirect('/customer/orders/1', user: _user()), isNull);
      expect(
        _redirect('/admin/customers/9', user: _user(role: AppRole.admin)),
        isNull,
      );
    });

    test('shared screens are open to every role', () {
      for (final role in AppRole.values) {
        expect(
          _redirect(Routes.notifications, user: _user(role: role)),
          isNull,
          reason: role.name,
        );
      }
    });

    test('a path that merely starts with a role name is not that area', () {
      expect(_redirect('/administrator', user: _user()), isNull);
    });
  });
}
