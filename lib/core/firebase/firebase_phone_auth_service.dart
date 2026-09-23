import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Phone Auth used ONLY to prove ownership of a phone number (free
/// SMS delivery) — the resulting ID token is handed to the
/// verify-phone-firebase Edge Function, which is what this app's database
/// actually trusts. Supabase remains the one real identity/session store;
/// no Firebase user is kept signed in beyond the moment of verification.
abstract class PhoneAuthService {
  /// Sends an SMS code to [phoneE164]. [onCodeSent] fires once it's on its
  /// way; [onError] fires for anything that stops it (bad number, quota,
  /// no network).
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
  });

  /// Confirms [code] against the last code sent and returns a Firebase ID
  /// token whose `phone_number` claim the server can trust. Throws on a
  /// wrong or expired code.
  Future<String> verifyCode(String code);
}

class FirebasePhoneAuthService implements PhoneAuthService {
  final _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      // Android's silent auto-retrieval/instant-verification path — this app
      // always asks the user to type the code (matches every other OTP
      // screen), so there is nothing to do here even when it fires.
      verificationCompleted: (_) {},
      verificationFailed: (e) =>
          onError(e.message ?? 'تعذر إرسال الكود، حاول مرة أخرى'),
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  @override
  Future<String> verifyCode(String code) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw StateError('لم يتم إرسال كود بعد');
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    final result = await _auth.signInWithCredential(credential);
    final token = await result.user?.getIdToken();
    // Firebase's job ends here — sign back out so nothing lingers signed in
    // on this device under Firebase's own identity.
    await _auth.signOut();
    if (token == null) {
      throw StateError('تعذر تأكيد الرقم، حاول مرة أخرى');
    }
    return token;
  }
}
