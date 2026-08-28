import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../data/reference_repository.dart';
import '../../data/verification_repository.dart';
import '../../models/city.dart';
import '../../models/ritual.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pickers.dart';

/// Registration for a purohit.
///
/// Deliberately one long form rather than a wizard: a purohit fills this in
/// once, often on a borrowed phone, and a multi-step flow that loses state
/// between pages is worse than a single scroll.
///
/// Nothing here can make a purohit visible to families. `pandit_profiles.status`
/// stays `pending` (the column is never sent — the `guard_pandit_status`
/// trigger would reject it anyway) until an admin approves from the console.
class RegisterPurohitPage extends ConsumerStatefulWidget {
  const RegisterPurohitPage({super.key});

  @override
  ConsumerState<RegisterPurohitPage> createState() =>
      _RegisterPurohitPageState();
}

enum _Proof { certificate, guru }

class _RegisterPurohitPageState extends ConsumerState<RegisterPurohitPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  final _languages = TextEditingController();
  final _fee = TextEditingController();
  final _radius = TextEditingController(text: '25');

  // Certificate path.
  final _institution = TextEditingController();
  final _documentUrl = TextEditingController();
  String _certKind = 'gurukul';
  DateTime? _issuedOn;

  // Guru-reference path.
  final _guruName = TextEditingController();
  final _guruPhone = TextEditingController();
  final _gurukulName = TextEditingController();
  final _guruYears = TextEditingController();
  final _guruNotes = TextEditingController();

  City? _city;
  _Proof _proof = _Proof.certificate;
  final Set<int> _ritualIds = {};
  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _name,
      _bio,
      _years,
      _languages,
      _fee,
      _radius,
      _institution,
      _documentUrl,
      _guruName,
      _guruPhone,
      _gurukulName,
      _guruYears,
      _guruNotes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Called from build so it also runs for the returning-purohit case, where
  /// the session arrives a frame or two after the first paint.
  void _prefill(SessionState session) {
    if (_prefilled) return;
    final profile = session.profile;
    final pandit = session.pandit;
    if (profile == null) return;
    _prefilled = true;

    // `handle_new_user()` inserts a placeholder name on signup; showing it back
    // as if the purohit typed it is worse than an empty field.
    if (profile.fullName.isNotEmpty && profile.fullName != 'New user') {
      _name.text = profile.fullName;
    }
    if (pandit != null) {
      _bio.text = pandit.bio ?? '';
      if (pandit.experienceYears != null) {
        _years.text = pandit.experienceYears.toString();
      }
      if (pandit.baseFee != null) {
        _fee.text = pandit.baseFee!.toStringAsFixed(0);
      }
      _radius.text = pandit.serviceRadiusKm.toString();
      if (pandit.languages.isNotEmpty) {
        _languages.text = pandit.languages.join(', ');
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(verificationRepositoryProvider);

      await repo.registerAsPurohit(
        fullName: _name.text,
        cityId: _city?.id,
        bio: _bio.text,
        experienceYears: int.tryParse(_years.text.trim()),
        serviceRadiusKm: int.tryParse(_radius.text.trim()),
        baseFee: double.tryParse(_fee.text.trim()),
        languages: _languages.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      if (_ritualIds.isNotEmpty) {
        await repo.setSpecialisations(_ritualIds.toList());
      }

      if (_proof == _Proof.certificate) {
        await repo.addCertificate(
          institution: _institution.text,
          kind: _certKind,
          issuedOn: _issuedOn,
          documentUrl: _documentUrl.text,
        );
      } else {
        await repo.addGuruReference(
          guruName: _guruName.text,
          guruPhone: _guruPhone.text,
          gurukulName: _gurukulName.text,
          yearsStudied: int.tryParse(_guruYears.text.trim()),
          notes: _guruNotes.text,
        );
      }

      await ref.read(sessionProvider.notifier).refresh();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted. An admin will review it soon.'),
        ),
      );
      context.go('/profile');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    _prefill(session);

    final cities = ref.watch(citiesProvider);
    final rituals = ref.watch(claimableRitualsProvider);
    final alreadyRegistered = session.pandit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(alreadyRegistered
            ? 'Purohit details'
            : 'Register as a purohit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
          children: [
            const _Note(
              'Your profile stays private until an admin verifies your Gurukul '
              'certificate or guru reference. Only verified purohits appear to '
              'families and can see the job feed.',
            ),
            const SizedBox(height: Gap.xl),

            const _SectionTitle('About you'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Pandit Ramesh Sharma',
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: Gap.md),
            cities.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load cities: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (list) => PickerField<City>(
                label: 'Base city',
                hint: 'Where do you usually serve?',
                value: _city,
                items: list,
                labelOf: (c) => c.label,
                onChanged: (c) => setState(() => _city = c),
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _years,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Years of experience',
                      hintText: '12',
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null) return 'Required';
                      // Matches the 0..90 CHECK constraint on the column.
                      if (n < 0 || n > 90) return '0-90';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: TextFormField(
                    controller: _radius,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Travel radius (km)',
                      hintText: '25',
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null) return 'Required';
                      if (n < 1 || n > 500) return '1-500';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _fee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Usual dakshina (INR, optional)',
                hintText: '5100',
              ),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _languages,
              decoration: const InputDecoration(
                labelText: 'Languages',
                hintText: 'Hindi, Sanskrit, Bhojpuri',
              ),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              maxLength: 600,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'About your practice',
                hintText:
                    'Parampara, where you trained, the ceremonies you are known for.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: Gap.lg),
            const _SectionTitle('Ceremonies you perform'),
            rituals.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load ceremonies: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (list) => Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.sm,
                children: [
                  for (final Ritual r in list)
                    FilterChip(
                      label: Text(r.name),
                      selected: _ritualIds.contains(r.id),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _ritualIds.add(r.id);
                        } else {
                          _ritualIds.remove(r.id);
                        }
                      }),
                    ),
                ],
              ),
            ),

            const SizedBox(height: Gap.xl),
            const _SectionTitle('Proof of training'),
            const Text(
              'Give us one of the two. A guru reference carries the same weight '
              'as a certificate — many respected purohits never attended a '
              'formal Gurukul.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.md),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Certificate'),
                  selected: _proof == _Proof.certificate,
                  onSelected: (_) =>
                      setState(() => _proof = _Proof.certificate),
                ),
                const SizedBox(width: Gap.sm),
                ChoiceChip(
                  label: const Text('Guru reference'),
                  selected: _proof == _Proof.guru,
                  onSelected: (_) => setState(() => _proof = _Proof.guru),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            if (_proof == _Proof.certificate) ..._certificateFields()
            else ..._guruFields(),

            if (_error != null) ...[
              const SizedBox(height: Gap.lg),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],

            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(alreadyRegistered
                      ? 'Save and resubmit'
                      : 'Submit for verification'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _certificateFields() => [
        Wrap(
          spacing: Gap.sm,
          children: [
            for (final k in const ['gurukul', 'degree', 'other'])
              ChoiceChip(
                label: Text(k[0].toUpperCase() + k.substring(1)),
                selected: _certKind == k,
                onSelected: (_) => setState(() => _certKind = k),
              ),
          ],
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _institution,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Institution',
            hintText: 'Shri Kashi Vishwanath Sanskrit Vidyalaya',
          ),
          validator: (v) => _proof == _Proof.certificate &&
                  (v == null || v.trim().length < 3)
              ? 'Where did you study?'
              : null,
        ),
        const SizedBox(height: Gap.md),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _issuedOn ?? DateTime(now.year - 5),
              firstDate: DateTime(1950),
              lastDate: now,
            );
            if (picked != null) setState(() => _issuedOn = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Issued on (optional)'),
            child: Text(
              _issuedOn == null
                  ? 'Select a date'
                  : '${_issuedOn!.day.toString().padLeft(2, '0')}/'
                      '${_issuedOn!.month.toString().padLeft(2, '0')}/'
                      '${_issuedOn!.year}',
              style: TextStyle(
                color:
                    _issuedOn == null ? AppColors.inkFaint : AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _documentUrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Link to a scan (optional)',
            hintText: 'Google Drive or DigiLocker link',
            helperText: 'You can add this later — an admin may ask for it.',
          ),
        ),
      ];

  List<Widget> _guruFields() => [
        TextFormField(
          controller: _guruName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Guru's name",
            hintText: 'Pandit Shivkumar Shastri',
          ),
          validator: (v) =>
              _proof == _Proof.guru && (v == null || v.trim().length < 3)
                  ? "Please enter your guru's name"
                  : null,
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _guruPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Guru's phone (optional)",
            helperText: 'Used only to confirm your training.',
          ),
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _gurukulName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Gurukul or math (optional)',
          ),
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _guruYears,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Years studied under them (optional)',
          ),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return null;
            final n = int.tryParse(v!.trim());
            if (n == null || n < 0 || n > 90) return '0-90';
            return null;
          },
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _guruNotes,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Anything else (optional)',
            alignLabelWithHint: true,
          ),
        ),
      ];
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Gap.md),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: AppColors.marigold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_outlined,
                size: 20, color: AppColors.saffronDark),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: AppColors.inkMuted),
              ),
            ),
          ],
        ),
      );
}
