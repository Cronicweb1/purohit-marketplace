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
