import 'dart:async';
import 'dart:convert';

/// Abstract key-value persistence interface.
abstract class Storage {
  const Storage();

  /// Reads a string value for the given [key]. Returns null if not found.
  FutureOr<String?> read(String key);

  /// Writes a string [value] for the given [key].
  FutureOr<void> write(String key, String value);

  /// Removes the entry for [key].
  FutureOr<void> delete(String key);

  /// Deletes all stored entries.
  FutureOr<void> clear();

  /// Checks whether [key] exists in storage.
  FutureOr<bool> containsKey(String key);

  /// Reads a JSON map from storage for [key]. Returns null if key is missing or invalid.
  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = await read(key);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  /// Serializes [value] to JSON and writes it to [key].
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await write(key, jsonEncode(value));
  }

  /// Returns all stored key-value pairs.
  FutureOr<Map<String, String>> readAll();
}

/// An in-memory implementation of [Storage] suitable for testing and runtime session caching.
class MemoryStorage extends Storage {
  final Map<String, String> _data = {};

  MemoryStorage([Map<String, String>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
    }
  }

  @override
  FutureOr<String?> read(String key) => _data[key];

  @override
  FutureOr<void> write(String key, String value) {
    _data[key] = value;
  }

  @override
  FutureOr<void> delete(String key) {
    _data.remove(key);
  }

  @override
  FutureOr<void> clear() {
    _data.clear();
  }

  @override
  FutureOr<bool> containsKey(String key) => _data.containsKey(key);

  @override
  FutureOr<Map<String, String>> readAll() => Map<String, String>.unmodifiable(_data);
}
