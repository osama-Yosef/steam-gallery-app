import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Whether the last request to the backend got an answer. Flipped by
/// [OfflineHttpClient] on every request, so it reflects the backend actually
/// being reachable rather than just "the device has a network interface".
class NetworkStatus extends ValueNotifier<bool> {
  NetworkStatus._() : super(true);
  static final instance = NetworkStatus._();

  bool get isOnline => value;

  void markOnline() {
    if (!value) value = true;
  }

  void markOffline() {
    if (value) value = false;
  }
}

/// True for failures where the request never got a server answer — the
/// cases where serving a cached copy, or queueing a write, is right. A
/// server that answered with an error (RLS, a raised exception) is NOT one.
bool isNetworkError(Object e) {
  if (e is http.ClientException || e is TimeoutException) return true;
  if (e is AuthRetryableFetchException) return true;
  if (e is RealtimeSubscribeException) return true;
  final s = e.toString();
  return s.contains('SocketException') ||
      s.contains('HandshakeException') ||
      s.contains('Failed host lookup') ||
      s.contains('Connection refused') ||
      s.contains('Connection closed') ||
      s.contains('XMLHttpRequest error') ||
      s.contains('Failed to fetch');
}
