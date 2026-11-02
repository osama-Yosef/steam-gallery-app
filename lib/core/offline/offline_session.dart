import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'network_status.dart';

/// Keeps the signed-in session usable while the server can't be reached.
///
/// The access token lives an hour and is renewed online. Once it has run
/// out, supabase refuses to send any request until a renewal succeeds — the
/// request never reaches [OfflineHttpClient], so no cached copy is served
/// and writes fail instead of queueing. Offline for more than an hour, the
/// app went blank, and after a restart it fell back to the login screen.
///
/// While the server can't be reached, this moves the session's local expiry
/// ahead, so requests go out with the old token and fail at the network —
/// where the cache answers reads and the [Outbox] queues writes. The token
/// itself is untouched (the server still checks it) and the refresh token is
/// kept, so the first renewal that gets through restores a real session.
class OfflineSession {
  OfflineSession(
    this._auth, {
    NetworkStatus? network,
    this.checkEvery = const Duration(seconds: 20),
  }) : _network = network ?? NetworkStatus.instance;

  final GoTrueClient _auth;
  final NetworkStatus _network;

  /// How often an expired token is retried for renewal. Null turns the
  /// timer off (tests call [check] themselves).
  final Duration? checkEvery;

  /// How far ahead the local expiry is moved; renewed on every [check], so
  /// it only needs to outlast the gap between two checks.
  static const _grace = Duration(minutes: 5);

  /// How long to wait for a renewal before carrying the session. Online it
  /// takes well under a second; offline, supabase keeps retrying with
  /// backoff, and app start must not sit on the splash screen through that.
  /// A renewal still running past this replaces the session when it lands.
  static const _renewTimeout = Duration(seconds: 4);

  Timer? _timer;
  StreamSubscription<AuthState>? _authSub;
  Future<void>? _renewing;

  /// Renews (or carries) an expired session, then keeps watching. Awaited
  /// in main() before the first screen asks for anything.
  Future<void> start() async {
    _network.addListener(_onNetwork);
    // A failed background renewal arrives as an error on this stream.
    _authSub = _auth.onAuthStateChange.listen(
      (_) {},
      onError: (Object e) {
        if (isNetworkError(e)) {
          _network.markOffline();
          _carry();
        }
      },
    );
    final every = checkEvery;
    if (every != null) {
      _timer = Timer.periodic(every, (_) => unawaited(check()));
    }
    await check();
  }

  void _onNetwork() {
    if (_network.isOnline) unawaited(check());
  }

  /// If the token has run out, tries to renew it; if the server can't be
  /// reached, carries the session until the next check.
  Future<void> check() =>
      _renewing ??= _check().whenComplete(() => _renewing = null);

  Future<void> _check() async {
    final session = _auth.currentSession;
    if (session == null || !_tokenExpired(session)) return;
    try {
      await _auth.refreshSession().timeout(_renewTimeout);
    } catch (e) {
      if (isNetworkError(e)) {
        _network.markOffline();
        _carry();
      }
      // Anything else (a revoked refresh token) has signed the user out
      // already — nothing to carry.
    }
  }

  /// Moves the local expiry of an expired session ahead by [_grace].
  void _carry() {
    final session = _auth.currentSession;
    if (session == null || !_tokenExpired(session)) return;
    session.expiresAt =
        DateTime.now().add(_grace).millisecondsSinceEpoch ~/ 1000;
  }

  /// Whether the access token itself (not the local expiry, which [_carry]
  /// may have moved) is expired or about to be.
  static bool _tokenExpired(Session session) {
    final exp = _jwtExp(session.accessToken);
    if (exp == null) return false;
    return DateTime.now()
        .add(const Duration(seconds: 30))
        .isAfter(DateTime.fromMillisecondsSinceEpoch(exp * 1000));
  }

  static int? _jwtExp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'];
      return exp is num ? exp.toInt() : null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _timer?.cancel();
    _authSub?.cancel();
    _network.removeListener(_onNetwork);
  }
}
