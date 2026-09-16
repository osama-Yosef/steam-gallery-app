import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import 'package:steam_gallery_app/core/errors/app_exception.dart';
import 'package:steam_gallery_app/core/utils/validators.dart';
import 'package:steam_gallery_app/features/auth/data/repositories/auth_repository.dart';
import 'package:steam_gallery_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:steam_gallery_app/features/auth/presentation/screens/otp_verify_screen.dart';

/// Records the OTP calls the screen makes; anything else is unexpected here.
class _FakeAuthRepository implements AuthRepository {
  final calls = <String>[];
  Object? verifyError;
  Uint8List? avatarPassed;

  @override
  Future<void> verifySignupOtp({
    required String phoneE164,
    required String code,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    calls.add('verifySignup:$phoneE164:$code');
    avatarPassed = avatarBytes;
    if (verifyError != null) throw verifyError!;
  }

  @override
  Future<void> verifySignInOtp({
    required String phoneE164,
    required String code,
  }) async {
    calls.add('verifySignIn:$phoneE164:$code');
    if (verifyError != null) throw verifyError!;
  }

  @override
  Future<void> resendSignupOtp(String phoneE164) async =>
      calls.add('resendSignup:$phoneE164');

  @override
  Future<void> sendSignInOtp(String phoneE164) async =>
      calls.add('sendSignIn:$phoneE164');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not expected');
}

const _phone = '+201012345678';

Future<(ProviderContainer, _FakeAuthRepository)> _pumpOtpScreen(
  WidgetTester tester,
  OtpRequest? request,
) async {
  final repo = _FakeAuthRepository();
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  if (request != null) {
    container.read(pendingOtpProvider.notifier).start(request);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OtpVerifyScreen()),
    ),
  );
  return (container, repo);
}

Finder get _codeField => find.byKey(const Key('otp-code-field'));
Finder get _resend => find.byKey(const Key('otp-resend-button'));

void main() {
  group('Validators', () {
    test('otpCode accepts exactly six digits', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode(''), isNotNull);
      expect(Validators.otpCode('12345'), isNotNull);
      expect(Validators.otpCode('1234567'), isNotNull);
      expect(Validators.otpCode('12a456'), isNotNull);
    });

    test('confirmPassword requires a valid, matching password', () {
      final validator = Validators.confirmPassword(() => 'secret-123');
      expect(validator('secret-123'), isNull);
      expect(validator('secret-124'), isNotNull);
      expect(Validators.confirmPassword(() => 'short')('short'), isNotNull);
    });
  });

  group('AppException auth messages', () {
    String auth(String code) =>
        AppException.from(AuthException('x', code: code)).messageAr;

    test('OTP and account codes get specific Arabic messages', () {
      expect(auth('otp_expired'), contains('الكود'));
      expect(auth('user_banned'), contains('موقوف'));
      expect(auth('over_sms_send_rate_limit'), contains('محاولات'));
      expect(auth('phone_exists'), contains('مسجَّل'));
    });

    test('unknown auth errors never leak the raw message', () {
      expect(
        AppException.from(
          const AuthException('db error: relation users does not exist'),
        ).messageAr,
        isNot(contains('relation')),
      );
    });

    test('RPC verification codes map to Arabic', () {
      expect(
        AppException.from(
          const PostgrestException(message: 'OTP_SESSION_REQUIRED'),
        ).messageAr,
        contains('الكود'),
      );
    });
  });

  group('OtpVerifyScreen', () {
    testWidgets('without a pending request it offers to start over', (
      tester,
    ) async {
      await _pumpOtpScreen(tester, null);
      expect(find.text('الرجوع لتسجيل الدخول'), findsOneWidget);
      expect(_codeField, findsNothing);
    });

    testWidgets(
      'signup: a full code verifies with the photo and clears state',
      (tester) async {
        final avatar = Uint8List.fromList([1, 2, 3]);
        final (container, repo) = await _pumpOtpScreen(
          tester,
          OtpRequest(
            phoneE164: _phone,
            purpose: OtpPurpose.signup,
            avatarBytes: avatar,
            avatarExt: 'jpg',
          ),
        );

        await tester.enterText(_codeField, '123456');
        await tester.pump();

        expect(repo.calls, ['verifySignup:$_phone:123456']);
        expect(repo.avatarPassed, avatar);
        expect(container.read(pendingOtpProvider), isNull);
        expect(container.read(passwordRecoveryProvider), isFalse);
      },
    );

    testWidgets('an incomplete code is not sent', (tester) async {
      final (_, repo) = await _pumpOtpScreen(
        tester,
        const OtpRequest(phoneE164: _phone, purpose: OtpPurpose.signup),
      );
      await tester.enterText(_codeField, '123');
      await tester.tap(find.byKey(const Key('otp-verify-button')));
      await tester.pump();
      expect(repo.calls, isEmpty);
      expect(find.text('الكود 6 أرقام'), findsOneWidget);
    });

    testWidgets('recovery: success keeps the router on the new-password step', (
      tester,
    ) async {
      final (container, repo) = await _pumpOtpScreen(
        tester,
        const OtpRequest(
          phoneE164: _phone,
          purpose: OtpPurpose.passwordRecovery,
        ),
      );
      await tester.enterText(_codeField, '654321');
      await tester.pump();

      expect(repo.calls, ['verifySignIn:$_phone:654321']);
      expect(container.read(passwordRecoveryProvider), isTrue);
    });

    testWidgets('recovery: a wrong code releases the hold and shows why', (
      tester,
    ) async {
      final (container, repo) = await _pumpOtpScreen(
        tester,
        const OtpRequest(
          phoneE164: _phone,
          purpose: OtpPurpose.passwordRecovery,
        ),
      );
      repo.verifyError = AppException.from(
        AuthException('Token has expired or is invalid', code: 'otp_expired'),
      );

      await tester.enterText(_codeField, '000000');
      await tester.pump();

      expect(container.read(passwordRecoveryProvider), isFalse);
      expect(container.read(pendingOtpProvider), isNotNull);
      expect(find.text('الكود غير صحيح أو انتهت صلاحيته'), findsOneWidget);
    });

    testWidgets('resend is locked for the cooldown, then uses the right call', (
      tester,
    ) async {
      final (_, repo) = await _pumpOtpScreen(
        tester,
        const OtpRequest(
          phoneE164: _phone,
          purpose: OtpPurpose.passwordRecovery,
        ),
      );

      expect(tester.widget<TextButton>(_resend).onPressed, isNull);

      await tester.pump(const Duration(seconds: 61));
      expect(tester.widget<TextButton>(_resend).onPressed, isNotNull);

      await tester.tap(_resend);
      await tester.pump();
      expect(repo.calls, ['sendSignIn:$_phone']);
      // Locked again right after sending.
      expect(tester.widget<TextButton>(_resend).onPressed, isNull);

      // Let the cooldown timer finish so no timer outlives the test.
      await tester.pump(const Duration(seconds: 61));
    });
  });
}
