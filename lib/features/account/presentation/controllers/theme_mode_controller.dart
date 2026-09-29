import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/secure_storage_service.dart';

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future<void>.microtask(_restore);
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    try {
      final String? raw =
          await ref.read(secureStorageProvider).read(key: StorageKeys.themeMode);
      final ThemeMode? mode = _parse(raw);
      if (mode != null && mode != state) state = mode;
    } on Object {
      // Missing plugin / empty keychain in tests — keep [ThemeMode.system].
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await ref.read(secureStorageProvider).write(
            key: StorageKeys.themeMode,
            value: mode.name,
          );
    } on Object {
      // Persist is best-effort.
    }
  }

  static ThemeMode? _parse(String? raw) {
    for (final ThemeMode mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return null;
  }
}
