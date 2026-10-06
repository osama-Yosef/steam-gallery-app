import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'offline_store.dart';

Future<OfflineStore> openOfflineStore() async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory('${base.path}${Platform.pathSeparator}offline');
  await dir.create(recursive: true);
  return _FileOfflineStore(dir);
}

class _FileOfflineStore implements OfflineStore {
  final Directory _dir;
  _FileOfflineStore(this._dir);

  /// Cache keys are whole request URLs — far too long and too odd for a file
  /// name — so files are named by a 64-bit FNV-1a hash of the key.
  File _file(String key) {
    // FNV offset basis 0xcbf29ce484222325 as a signed 64-bit literal; native
    // int arithmetic wraps at 64 bits, which is exactly what FNV wants.
    var hash = -3750763034362895579;
    for (final b in utf8.encode(key)) {
      hash ^= b;
      hash *= 0x100000001b3;
    }
    final prefix = key.startsWith('cache:') ? 'c_' : 'k_';
    return File(
      '${_dir.path}${Platform.pathSeparator}$prefix${hash.toUnsigned(64).toRadixString(16)}.json',
    );
  }

  @override
  Future<String?> read(String key) async {
    try {
      final f = _file(key);
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final f = _file(key);
    // Write-then-rename so a crash mid-write never leaves a torn file behind.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(value, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _file(key).delete();
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    await for (final e in _dir.list()) {
      if (e is File && e.uri.pathSegments.last.startsWith('c_')) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}
