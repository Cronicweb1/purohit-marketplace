import 'package:flutter/widgets.dart';

/// The languages the *interface* is available in.
///
/// Deliberately separate from [IndianLanguage] in `data/languages.dart`. That
/// list answers "which languages does this purohit chant in", is persisted to
/// `pandit_profiles.languages`, and runs to 37 entries. This one answers "which
/// language is this app drawn in" and only grows when a translation table is
/// actually written. Conflating them would put 37 options in the picker, 35 of
/// which would render an untranslated screen.
enum AppLocale {
  en('en', 'English', 'English'),
  hi('hi', 'Hindi', 'हिन्दी');

  const AppLocale(this.code, this.englishName, this.nativeName);

  /// ISO-639-1. Stored in SharedPreferences and handed to [Locale].
  final String code;
  final String englishName;

  /// Shown in the picker in its own script, so someone who cannot read the
  /// current interface language can still find their own.
  final String nativeName;

  Locale get locale => Locale(code);

  /// Unknown or absent codes fall back to English rather than throwing. A
  /// corrupt preference value must never be able to stop the app booting.
  static AppLocale fromCode(String? code) {
    for (final l in AppLocale.values) {
      if (l.code == code) return l;
    }
    return AppLocale.en;
  }
}
