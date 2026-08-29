import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/jobs_repository.dart';
import '../../data/reference_repository.dart';
import '../../models/city.dart';
import '../../models/job.dart';
import '../../models/ritual.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pickers.dart';

class PostJobPage extends ConsumerStatefulWidget {
  const PostJobPage({super.key, this.initialRitualId});

  final int? initialRitualId;

  @override
  ConsumerState<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends ConsumerState<PostJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _budget = TextEditingController();

  Ritual? _ritual;
  City? _city;
  DateTime? _startDate;
  DateTime? _endDate;
  JobUrgency _urgency = JobUrgency.scheduled;
  bool _busy = false;
  String? _error;
  bool _seeded = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      setState(() => _error = 'Pick the ceremony date.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final job = await ref.read(jobsRepositoryProvider).create(
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            startDate: _startDate!,
            endDate: _endDate,
            ritualId: _ritual?.id,
            cityId: _city?.id,
            budget: num.tryParse(_budget.text.trim()),
            urgency: _urgency,
          );
      ref.invalidate(myJobsProvider);
      if (!mounted) return;
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted. Verified purohits can see it now.')),
      );
      // push, not go: /jobs/:id lives on the root navigator, so go() would
      // replace the whole stack and strand the family with no way back.
      context.push('/jobs/${job.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _title.clear();
    _description.clear();
    _budget.clear();
    setState(() {
      _ritual = null;
      _city = null;
      _startDate = null;
      _endDate = null;
      _urgency = JobUrgency.scheduled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rituals = ref.watch(bookableRitualsProvider);
    final cities = ref.watch(citiesProvider);

    // Seed the ritual when arriving from a "Browse" tap.
    final seedId = widget.initialRitualId;
    final seedList = rituals.asData?.value;
    if (!_seeded && seedId != null && seedList != null) {
      for (final r in seedList) {
        if (r.id == seedId) {
          _seeded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _ritual = r;
              if (_title.text.isEmpty) _title.text = '${r.name} at home';
            });
          });
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a ceremony'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Gap.lg),
          children: [
            const Text('Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.sm),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Griha Pravesh for a new flat in Andheri',
              ),
              validator: (v) =>
                  (v ?? '').trim().length < 6 ? 'Give it a clearer title' : null,
            ),
            const SizedBox(height: Gap.lg),
            rituals.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
              data: (list) => PickerField<Ritual>(
                label: 'Ceremony',
                hint: 'Select the ritual',
                value: _ritual,
                items: list,
                labelOf: (r) => r.name,
                onChanged: (r) => setState(() => _ritual = r),
              ),
            ),
            const SizedBox(height: Gap.lg),
            cities.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
              data: (list) => PickerField<City>(
                label: 'City',
                hint: 'Where is it happening?',
                value: _city,
                items: list,
                labelOf: (c) => c.label,
                onChanged: (c) => setState(() => _city = c),
              ),
            ),
            const SizedBox(height: Gap.lg),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start date',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: _DateField(
                    label: 'End date (optional)',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            const Text('Budget (₹, optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.sm),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Leave blank to invite quotes',
              ),
            ),
            const SizedBox(height: Gap.lg),
            const Text('Urgency',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.sm),
            Wrap(
              spacing: Gap.sm,
              children: [
                for (final u in JobUrgency.values)
                  ChoiceChip(
                    label: Text(u.label),
                    selected: _urgency == u,
                    onSelected: (_) => setState(() => _urgency = u),
                  ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            const Text('Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.sm),
            TextFormField(
              controller: _description,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Number of guests, samagri arranged or not, language '
                    'preference, timings…',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Gap.lg),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post ceremony'),
            ),
            const SizedBox(height: Gap.md),
            const Text(
              'Your phone number is never shown. A purohit only gets your '
              'contact details after you select them.',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint, height: 1.4),
            ),
            const SizedBox(height: Gap.xxl),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: Gap.sm),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.field),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.lg,
              vertical: Gap.lg - 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? 'Select' : formatDate(value),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: value == null ? AppColors.inkFaint : AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.event, size: 18, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
