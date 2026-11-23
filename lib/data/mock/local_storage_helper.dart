// Safe Hive key-value storage wrapper with seamless in-memory fallback for tests.

import 'package:hive_flutter/hive_flutter.dart';

/// Persists JSON-compatible values in a Hive box, falling back to memory when
/// Hive is uninitialized (such as in pure Dart or widget unit tests).
class LocalKeyValueStore {
  /// Creates a [LocalKeyValueStore] backed by Hive box [boxName].
  LocalKeyValueStore(this.boxName);

  /// Name of the underlying Hive box.
  final String boxName;

  final Map<String, dynamic> _memory = {};

  Future<Box<dynamic>?> _openBoxSafely() async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<dynamic>(boxName);
      }
      // Probe boxExists first so uninitialized Hive throws ArgumentError cleanly
      // without triggering HiveImpl._openBox's orphaned Completer error.
      await Hive.boxExists(boxName);
      return await Hive.openBox<dynamic>(boxName);
    } catch (_) {
      // Hive has not been initialized in this environment; keep using memory.
      return null;
    }
  }

  /// Reads a stored value by [key], or null if absent.
  Future<dynamic> read(String key) async {
    final box = await _openBoxSafely();
    if (box != null) {
      return box.get(key);
    }
    return _memory[key];
  }

  /// Writes [value] under [key] to Hive or the in-memory fallback map.
  Future<void> write(String key, dynamic value) async {
    _memory[key] = value;
    final box = await _openBoxSafely();
    if (box != null) {
      await box.put(key, value);
    }
  }

  /// Deletes [key] from Hive and memory.
  Future<void> delete(String key) async {
    _memory.remove(key);
    final box = await _openBoxSafely();
    if (box != null) {
      await box.delete(key);
    }
  }

  /// Returns all stored entries keyed as strings.
  Future<Map<String, dynamic>> readAllEntries() async {
    final box = await _openBoxSafely();
    if (box != null) {
      final result = <String, dynamic>{};
      for (final key in box.keys) {
        result[key.toString()] = box.get(key);
      }
      return result;
    }
    return Map<String, dynamic>.from(_memory);
  }

  /// Clears every key-value entry from Hive and memory.
  Future<void> clear() async {
    _memory.clear();
    final box = await _openBoxSafely();
    if (box != null) {
      await box.clear();
    }
  }
}
