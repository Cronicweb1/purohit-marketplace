import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'app_strings.dart';

/// Key under which the chosen interface language is persisted.
const kLocalePrefKey = 'app_locale';

/// Overridden in `main()` with the value read from disk *before* the first
/// frame. Without that override the app would paint one frame in English and
/// then snap to Hindi, which reads as a bug even though it is only a race.
final savedLocaleProvider = Provider<AppLocale>((ref) {
  throw UnimplementedError('savedLocaleProvider must be overridden in main()');
});

class LocaleController extends StateNotifier<AppLocale> {
  LocaleController(super.initial);

  Future<void> set(AppLocale locale) async {
    if (locale == state) return;
    state = locale;
    // Fire and forget is fine: the in-memory state is already correct, and a
    // failed write only costs the preference on next launch.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocalePrefKey, locale.code);
    } catch (_) {
      // Storage unavailable (rare, and never in a way the user can act on).
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleController, AppLocale>(
  (ref) => LocaleController(ref.watch(savedLocaleProvider)),
);

/// The active translation table.
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.of(ref.watch(localeProvider)),
);

/// Reads the persisted language, falling back to the device language when the
/// user has never chosen one, and to English when the device speaks something
/// we have not translated yet.
Future<AppLocale> loadSavedLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kLocalePrefKey);
    if (stored != null) return AppLocale.fromCode(stored);
  } catch (_) {
    // Fall through to the device default.
  }
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return AppLocale.fromCode(device);
}

/// Sugar so widgets can write `ref.strings.signIn`.
extension StringsRef on WidgetRef {
  AppStrings get strings => read(stringsProvider);
}
