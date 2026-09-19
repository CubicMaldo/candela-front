import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_storage.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  final ThemeMode initialMode;
  ThemeNotifier(this.initialMode);

  @override
  ThemeMode build() {
    return initialMode;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await ThemeStorage.save(mode);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() => ThemeNotifier(ThemeMode.system));
