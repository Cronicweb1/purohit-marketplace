import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_locale.dart';
import '../core/l10n/locale_controller.dart';
import '../theme/app_theme.dart';

/// Opens the language sheet. Deliberately a modal sheet and not a route: a
/// route would need its own `leading:` back button on every screen that pushes
/// it (see admin sign-in), and a sheet dismisses with the same swipe on both
/// platforms.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final t = ref.watch(stringsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.languageTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              t.languageSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.md),
            for (final locale in AppLocale.values)
              RadioListTile<AppLocale>(
                value: locale,
                groupValue: current,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  locale.nativeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: locale.nativeName == locale.englishName
                    ? null
                    : Text(
                        locale.englishName,
                        style: const TextStyle(color: AppColors.inkFaint),
                      ),
                onChanged: (value) async {
                  if (value == null) return;
                  await ref.read(localeProvider.notifier).set(value);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact globe button for app bars and the landing page, where there is no
/// room for a label.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return TextButton.icon(
      onPressed: () => showLanguageSheet(context),
      icon: Icon(Icons.language, size: 18, color: color ?? AppColors.inkMuted),
      label: Text(
        current.nativeName,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.inkMuted,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Full-width row for the profile screen, matching the other settings rows.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final t = ref.watch(stringsProvider);

    return OutlinedButton.icon(
      onPressed: () => showLanguageSheet(context),
      icon: const Icon(Icons.language),
      label: Text('${t.languageTitle} · ${current.nativeName}'),
    );
  }
}
