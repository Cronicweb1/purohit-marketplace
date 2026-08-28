import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A tappable field that opens a searchable bottom sheet.
///
/// Deliberately not `DropdownButtonFormField`: its `value`/`initialValue`
/// parameter was renamed across recent Flutter releases, and this project has no
/// local toolchain to compile against — an API that shifts between stable
/// versions is a CI failure waiting to happen. A bottom sheet is also the better
/// UX for a list of 100+ Indian cities, which a dropdown cannot search.
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    if (!enabled || items.isEmpty) return;

    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PickerSheet<T>(
        title: label,
        items: items,
        labelOf: labelOf,
        selected: value,
      ),
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null ? hint : labelOf(value as T);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.sm),
        InkWell(
          onTap: enabled ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.lg - 2,
            ),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: value == null ? AppColors.inkFaint : AppColors.ink,
                    ),
                  ),
                ),
                if (value != null)
                  InkWell(
                    onTap: () => onChanged(null),
                    child: const Icon(Icons.close, size: 18, color: AppColors.inkFaint),
                  )
                else
                  const Icon(Icons.expand_more, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.selected,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final T? selected;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.items
        : widget.items
            .where((e) => widget.labelOf(e).toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: Gap.md),
            Container(
              height: 4,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Gap.md),
                  TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches',
                        style: TextStyle(color: AppColors.inkFaint),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final isSelected = item == widget.selected;
                        return ListTile(
                          title: Text(widget.labelOf(item)),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.saffron)
                              : null,
                          onTap: () => Navigator.of(ctx).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


/// The multi-select sibling of [PickerField], used for "Languages you conduct
/// ceremonies in".
///
/// It exists for the same reason [PickerField] does — see the note at the top
/// of this file about `DropdownButtonFormField` — plus one more: Flutter has no
/// stock multi-select control at all, and a row of FilterChips for ~37
/// languages would push the rest of the form off the screen. A searchable sheet
/// keeps the field one line tall no matter how many items are selected.
class MultiPickerField<T> extends StatelessWidget {
  const MultiPickerField({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? hint;

  /// Rendered by [InputDecorator] so a "pick at least one" message lines up
  /// with the validator messages on the surrounding TextFormFields.
  final String? errorText;

  final List<T> items;
  final Set<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<Set<T>> onChanged;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    if (!enabled || items.isEmpty) return;
    final result = await showModalBottomSheet<Set<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MultiPickerSheet<T>(
        title: label,
        items: items,
        selected: selected,
        labelOf: labelOf,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = items.where(selected.contains).toList();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.expand_more),
        ),
        child: chosen.isEmpty
            ? Text(
                hint ?? 'Tap to choose',
                style: const TextStyle(color: AppColors.inkFaint),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                child: Wrap(
                  spacing: Gap.xs,
                  runSpacing: Gap.xs,
                  children: [
                    for (final e in chosen)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Gap.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.saffronTint,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          labelOf(e),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.saffronDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _MultiPickerSheet<T> extends StatefulWidget {
  const _MultiPickerSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.labelOf,
  });

  final String title;
  final List<T> items;
  final Set<T> selected;
  final String Function(T) labelOf;

  @override
  State<_MultiPickerSheet<T>> createState() => _MultiPickerSheetState<T>();
}

class _MultiPickerSheetState<T> extends State<_MultiPickerSheet<T>> {
  late final Set<T> _draft = {...widget.selected};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final visible = _q.isEmpty
        ? widget.items
        : widget.items
            .where((e) => widget.labelOf(e).toLowerCase().contains(_q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: Gap.sm),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_draft.length} selected',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches',
                        style: TextStyle(color: AppColors.inkFaint),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.hairline),
                      itemBuilder: (_, i) {
                        final e = visible[i];
                        final on = _draft.contains(e);
                        return ListTile(
                          onTap: () => setState(
                            () => on ? _draft.remove(e) : _draft.add(e),
                          ),
                          leading: Icon(
                            on
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: on ? AppColors.saffron : AppColors.inkFaint,
                          ),
                          title: Text(widget.labelOf(e)),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
