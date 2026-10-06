import 'package:shared_preferences/shared_preferences.dart';

import 'offline_store.dart';

Future<OfflineStore> openOfflineStore() async =>
    _PrefsOfflineStore(await SharedPreferences.getInstance());

class _PrefsOfflineStore implements OfflineStore {
  final SharedPreferences _prefs;
  _PrefsOfflineStore(this._prefs);

  static const _prefix = 'offline.';

  @override
  Future<String?> read(String key) async => _prefs.getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) async {
    try {
      await _prefs.setString('$_prefix$key', value);
    } catch (_) {
      // localStorage quota: drop the cache and keep going rather than fail
      // the request that was only trying to cache its response.
      await clearCache();
    }
  }

  @override
  Future<void> delete(String key) => _prefs.remove('$_prefix$key');

  @override
  Future<void> clearCache() async {
    for (final k in _prefs.getKeys().toList()) {
      if (k.startsWith('${_prefix}cache:')) await _prefs.remove(k);
    }
  }
}
