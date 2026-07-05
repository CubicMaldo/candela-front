import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's light/dark/system theme choice across app launches.
/// Reuses [FlutterSecureStorage] so the app keeps a single storage backend.
class ThemeStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'candela_theme_mode';

  /// Loads the saved theme mode; falls back to [ThemeMode.system] when nothing
  /// has been stored yet or the value is unreadable.
  static Future<ThemeMode> load() async {
    switch (await _storage.read(key: _key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> save(ThemeMode mode) => _storage.write(
    key: _key,
    value: switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    },
  );
}
