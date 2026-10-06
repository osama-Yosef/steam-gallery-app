import 'offline_store_io.dart'
    if (dart.library.js_interop) 'offline_store_web.dart'
    as impl;

/// A small persistent key/value store for offline data: cached API responses
/// and the queue of writes waiting to be sent.
///
/// Native builds keep one file per key under the app-support directory, so
/// caching a response never rewrites everything else (shared_preferences on
/// Windows rewrites its whole JSON file on every write). The web build uses
/// shared_preferences (localStorage), where that cost doesn't exist.
abstract class OfflineStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Removes every cached response (the write queue is kept).
  Future<void> clearCache();

  static Future<OfflineStore> open() => impl.openOfflineStore();
}
