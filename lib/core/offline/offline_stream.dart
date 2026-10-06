import 'network_status.dart';

extension OfflineTolerantStream<T> on Stream<T> {
  /// For Supabase `.stream()` lists. Their first value comes over REST, which
  /// [OfflineHttpClient] answers from the cache when offline; the realtime
  /// channel then fails to connect and reports that as a stream error, which
  /// would replace the cached list with an error screen. Connection errors
  /// are dropped here instead — the channel reconnects by itself and
  /// refetches once the network is back.
  Stream<T> offlineTolerant() =>
      handleError((Object _) {}, test: (e) => isNetworkError(e as Object));
}
