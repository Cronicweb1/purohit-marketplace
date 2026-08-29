import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session.dart';
import '../../core/supabase_providers.dart' show currentUserId;
import '../../data/storage_repository.dart';
import '../../data/reference_repository.dart';
import '../../data/verification_repository.dart';
import '../../data/languages.dart';
import '../../models/city.dart';
import '../../models/institution.dart';
import '../../models/kyc_document.dart';
import '../../core/format.dart';
import '../../models/ritual.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_upload_field.dart';
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

// Training proof used to be an either/or radio. It is now two independent
// flags: a purohit with both a Gurukul certificate AND a living guru is the
// strongest case we can get, and the old enum made that unrepresentable.

class _RegisterPurohitPageState extends ConsumerState<RegisterPurohitPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  final _fee = TextEditingController();
  final _radius = TextEditingController(text: '25');

  // Certificate path.
  final _institution = TextEditingController();

  /// Stored as ISO codes to match the rows already in `pandit_profiles.languages`.
  final Set<String> _languageCodes = <String>{};
  String? _langError;

  Institution? _inst;
  bool _instManual = false;
  Institution? _guruInst;
  bool _guruInstManual = false;
  final _documentUrl = TextEditingController();
  String _certKind = 'gurukul';
  DateTime? _issuedOn;

  // Guru-reference path.
  final _guruName = TextEditingController();
  final _guruPhone = TextEditingController();
  final _gurukulName = TextEditingController();
  final _guruYears = TextEditingController();
  final _guruNotes = TextEditingController();

  // Identity is compulsory; address proof is optional but becomes all-or-
  // nothing once a type is picked, so half-filled rows never reach an admin.
  KycDocType? _idType;
  PickedImage? _idImage;
  String? _idError;

  KycDocType? _addressType;
  PickedImage? _addressImage;
  String? _addressError;

  PickedImage? _certImage;

  City? _city;

  /// Required for new registrations. Nullable in the database only so that
  /// purohits who registered before migration 0007 are not locked out.
  DateTime? _dob;
  String? _dobError;

  bool _useCertificate = true;
  bool _useGuru = false;
  String? _proofError;
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
      _dob = pandit.dob;
      _bio.text = pandit.bio ?? '';
      if (pandit.experienceYears != null) {
        _years.text = pandit.experienceYears.toString();
      }
      if (pandit.baseFee != null) {
        _fee.text = pandit.baseFee!.toStringAsFixed(0);
      }
      _radius.text = pandit.serviceRadiusKm.toString();
      if (pandit.languages.isNotEmpty) {
        _languageCodes
          ..clear()
          ..addAll(pandit.languages);
      }
    }
  }

  /// The most recent birth date that still clears the 18-year floor.
  DateTime get _eighteenYearsAgo {
    final n = DateTime.now();
    return DateTime(n.year - 18, n.month, n.day);
  }

  /// Whichever of the picker or the free-text box is actually in play.
  String get _institutionName =>
      _instManual ? _institution.text.trim() : (_inst?.name ?? '');

  String get _guruInstitutionName =>
      _guruInstManual ? _gurukulName.text.trim() : (_guruInst?.name ?? '');

  String get _idTypeLabel => _idType?.label.toLowerCase() ?? 'ID card';

  /// Uploads before any row is written, so a storage failure leaves no
  /// half-registered purohit behind.
  Future<String?> _upload(PickedImage? image, String slot) async {
    if (image == null) return null;
    final uid = currentUserId;
    if (uid == null) throw StateError('Not signed in.');
    return ref.read(storageRepositoryProvider).upload(
          bucket: kVerificationBucket,
          path: verificationObjectPath(
              uid: uid, slot: slot, extension: image.extension),
          bytes: image.bytes,
          contentType: image.contentType,
        );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Two checks the Form can not run for us: MultiPickerField and PickerField
    // are not FormFields, so their emptiness has to be caught by hand.
    if (_dob == null) {
      setState(() => _dobError = 'Enter your date of birth.');
      return;
    }
    if (_languageCodes.isEmpty) {
      setState(() => _langError = 'Pick at least one language');
      return;
    }
    if (!_useCertificate && !_useGuru) {
      setState(() => _proofError =
          'Pick at least one: a certificate, a guru reference, or both.');
      return;
    }
    if (_useCertificate && _institutionName.length < 3) {
      setState(() =>
          _error = 'Choose the institution that issued your certificate.');
      return;
    }
    if (_idType == null) {
      setState(() => _idError = 'Choose which ID card you are submitting.');
      return;
    }
    if (_idImage == null) {
      setState(() => _idError = 'Attach a photo of your $_idTypeLabel.');
      return;
    }
    if (_addressType != null && _addressImage == null) {
      setState(() =>
          _addressError = 'Attach a photo, or clear the address proof type.');
      return;
    }
    if (_addressType == null && _addressImage != null) {
      setState(() => _addressError = 'Choose which document this is.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(verificationRepositoryProvider);

      await repo.registerAsPurohit(
        fullName: _name.text,
        cityId: _city?.id,
        dob: _dob,
        bio: _bio.text,
        experienceYears: int.tryParse(_years.text.trim()),
        serviceRadiusKm: int.tryParse(_radius.text.trim()),
        baseFee: double.tryParse(_fee.text.trim()),
        languages: _languageCodes.toList(),
      );

      if (_ritualIds.isNotEmpty) {
        await repo.setSpecialisations(_ritualIds.toList());
      }

      // Storage first. If the bucket rejects an image we fail here, before any
      // kyc_documents / certificates row claims a file that does not exist.
      final idPath = await _upload(_idImage, 'identity');
      final addressPath = await _upload(_addressImage, 'address');
      final certPath = await _upload(_certImage, 'certificate');

      if (idPath != null && _idType != null) {
        await repo.upsertKycDocument(
          role: KycRole.identity,
          docType: _idType!.code,
          storagePath: idPath,
          mimeType: _idImage?.contentType,
          sizeBytes: _idImage?.sizeBytes,
        );
      }
      if (addressPath != null && _addressType != null) {
        await repo.upsertKycDocument(
          role: KycRole.address,
          docType: _addressType!.code,
          storagePath: addressPath,
          mimeType: _addressImage?.contentType,
          sizeBytes: _addressImage?.sizeBytes,
        );
      }

      if (_useCertificate) {
        await repo.addCertificate(
          institution: _institutionName,
          kind: _certKind,
          issuedOn: _issuedOn,
          documentUrl: _documentUrl.text,
          storagePath: certPath,
        );
      }
      if (_useGuru) {
        await repo.addGuruReference(
          guruName: _guruName.text,
          guruPhone: _guruPhone.text,
          gurukulName: _guruInstitutionName,
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
            _DateField(
              label: 'Date of birth',
              hint: 'Select your date of birth',
              value: _dob,
              errorText: _dobError,
              // A purohit conducts ceremonies in strangers' homes. Under-18s
              // cannot be verified here, so the picker simply cannot reach
              // those years - a validator message would be a worse way to say
              // the same thing.
              firstDate: DateTime(1930),
              lastDate: _eighteenYearsAgo,
              initialDate: _dob ?? DateTime(_eighteenYearsAgo.year - 12, 1, 1),
              helper: _dob == null
                  ? 'You must be at least 18 to register as a purohit.'
                  : 'Age ${ageFrom(_dob!)}',
              onChanged: (d) => setState(() {
                _dob = d;
                _dobError = null;
              }),
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
            MultiPickerField<IndianLanguage>(
              label: 'Languages you conduct ceremonies in',
              hint: 'Hindi, Sanskrit, Bhojpuri…',
              items: IndianLanguages.ordered,
              selected: IndianLanguages.ordered
                  .where((l) => _languageCodes.contains(l.code))
                  .toSet(),
              labelOf: (l) => l.label,
              errorText: _langError,
              onChanged: (picked) => setState(() {
                _languageCodes
                  ..clear()
                  ..addAll(picked.map((l) => l.code));
                _langError = null;
              }),
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
            const _SectionTitle('Identity'),
            const Text(
              'A family is letting you into their home. We check who you are '
              'before anyone can book you. These scans are private: only you '
              'and a verifying admin can ever open them.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.md),
            PickerField<KycDocType>(
              label: 'ID card type',
              hint: 'Aadhaar, voter ID, PAN...',
              value: _idType,
              items: KycDocTypes.identity,
              labelOf: (t) => t.label,
              onChanged: (t) => setState(() {
                _idType = t;
                _idError = null;
              }),
            ),
            const SizedBox(height: Gap.md),
            ImageUploadField(
              label: 'Photo of your ID card',
              helper: 'Hold it flat in good light. Photos are shrunk to about '
                  '200-400 KB before they leave your phone.',
              value: _idImage,
              errorText: _idError,
              onChanged: (img) => setState(() {
                _idImage = img;
                _idError = null;
              }),
            ),

            const SizedBox(height: Gap.xl),
            const _SectionTitle('Address proof (optional)'),
            const Text(
              'Skip this for now if you like. Adding it usually gets your '
              'application approved faster.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.md),
            PickerField<KycDocType>(
              label: 'Address proof type',
              hint: 'Aadhaar, electricity bill...',
              value: _addressType,
              items: KycDocTypes.address,
              labelOf: (t) => t.label,
              onChanged: (t) => setState(() {
                _addressType = t;
                _addressError = null;
              }),
            ),
            const SizedBox(height: Gap.md),
            ImageUploadField(
              label: 'Photo of your address proof',
              helper: 'A bill has to be from the last three months.',
              value: _addressImage,
              errorText: _addressError,
              onChanged: (img) => setState(() {
                _addressImage = img;
                _addressError = null;
              }),
            ),

            const SizedBox(height: Gap.xl),
            const _SectionTitle('Proof of training'),
            const Text(
              'Give us at least one. A guru reference carries the same weight '
              'as a certificate - many respected purohits never attended a '
              'formal Gurukul. Having both is stronger than either alone.',
              style: TextStyle(
                  fontSize: 13, height: 1.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: Gap.md),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                FilterChip(
                  label: const Text('Certificate'),
                  selected: _useCertificate,
                  onSelected: (v) => setState(() {
                    _useCertificate = v;
                    _proofError = null;
                  }),
                ),
                FilterChip(
                  label: const Text('Guru reference'),
                  selected: _useGuru,
                  onSelected: (v) => setState(() {
                    _useGuru = v;
                    _proofError = null;
                  }),
                ),
              ],
            ),
            if (_proofError != null) ...[
              const SizedBox(height: Gap.sm),
              Text(_proofError!,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.danger)),
            ],
            const SizedBox(height: Gap.md),
            if (_useCertificate) ..._certificateFields(),
            if (_useCertificate && _useGuru) ...[
              const SizedBox(height: Gap.lg),
              const Divider(color: AppColors.hairline),
              const SizedBox(height: Gap.lg),
            ],
            if (_useGuru) ..._guruFields(),

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
        ..._institutionField(
          label: 'Institution',
          manual: _instManual,
          picked: _inst,
          controller: _institution,
          isRequired: _useCertificate,
          onPicked: (i) => setState(() {
            _inst = i;
            _error = null;
          }),
          onToggleManual: () => setState(() {
            _instManual = !_instManual;
            _error = null;
          }),
        ),
        const SizedBox(height: Gap.md),
        _DateField(
          label: 'Issued on (optional)',
          hint: 'Select a date',
          value: _issuedOn,
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          initialDate: _issuedOn ?? DateTime(DateTime.now().year - 5),
          onChanged: (d) => setState(() => _issuedOn = d),
        ),
        const SizedBox(height: Gap.md),
        ImageUploadField(
          label: 'Photo of the certificate',
          helper: 'Optional if you paste a link below, but a photo is faster '
              'for an admin to check.',
          value: _certImage,
          onChanged: (img) => setState(() => _certImage = img),
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _documentUrl,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Or paste a link to a scan',
            hintText: 'https://drive.google.com/...',
            helperText: 'Upload the scan to Google Drive or DigiLocker, set the '
                'link to "anyone with the link can view", then paste it here.',
            helperMaxLines: 3,
          ),
          validator: (v) {
            if (!_useCertificate) return null;
            final t = (v ?? '').trim();
            if (t.isEmpty && _certImage != null) return null;
            if (t.isEmpty) {
              return 'Attach a photo above, or paste a link here.';
            }
            final uri = Uri.tryParse(t);
            if (uri == null ||
                !uri.hasScheme ||
                (uri.scheme != 'http' && uri.scheme != 'https') ||
                (uri.host).isEmpty) {
              return 'Paste a full link starting with https://';
            }
            return null;
          },
        ),
      ];

  /// An institution picker with a free-text escape hatch.
  ///
  /// The seeded registry holds 128 Gurukuls, Veda Pathashalas and Sanskrit
  /// universities, but it can never be complete — there are thousands of
  /// village pathshalas with no web presence at all. Refusing an unlisted name
  /// would lock out exactly the purohits this app exists to reach, so the list
  /// is an aid to spelling, never a gate. A failed or empty load silently falls
  /// back to typing.
  List<Widget> _institutionField({
    required String label,
    required bool manual,
    required Institution? picked,
    required TextEditingController controller,
    required bool isRequired,
    required ValueChanged<Institution?> onPicked,
    required VoidCallback onToggleManual,
  }) {
    final async = ref.watch(institutionsProvider);
    final items = async.asData?.value ?? const <Institution>[];
    final typing = manual || async.hasError || (async.hasValue && items.isEmpty);

    return [
      if (typing)
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Shri Kashi Vishwanath Sanskrit Vidyalaya',
          ),
          validator: (v) => isRequired && (v == null || v.trim().length < 3)
              ? 'Where did you study?'
              : null,
        )
      else
        PickerField<Institution>(
          label: label,
          hint: async.isLoading
              ? 'Loading the list…'
              : 'Search Gurukuls, pathshalas and universities',
          value: picked,
          items: items,
          labelOf: (i) => i.label,
          onChanged: onPicked,
        ),
      if (manual || !typing)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onToggleManual,
            child: Text(
              manual ? 'Pick from the list instead' : 'Not in the list? Type it',
            ),
          ),
        ),
    ];
  }

  List<Widget> _guruFields() => [
        TextFormField(
          controller: _guruName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Guru's name",
            hintText: 'Pandit Shivkumar Shastri',
          ),
          validator: (v) =>
              _useGuru && (v == null || v.trim().length < 3)
                  ? "Please enter your guru's name"
                  : null,
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _guruPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Guru's phone",
            hintText: '98765 43210',
            helperText: 'We call your guru to confirm your training. Without a '
                'reachable number this route cannot be verified.',
            helperMaxLines: 3,
          ),
          validator: (v) {
            if (!_useGuru) return null;
            final t = (v ?? '').trim();
            if (t.isEmpty) return "Your guru's phone number is required";
            final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length < 10 || digits.length > 15) {
              return 'Enter a valid phone number with country or STD code';
            }
            return null;
          },
        ),
        const SizedBox(height: Gap.md),
        ..._institutionField(
          label: 'Gurukul or math (optional)',
          manual: _guruInstManual,
          picked: _guruInst,
          controller: _gurukulName,
          isRequired: false,
          onPicked: (i) => setState(() => _guruInst = i),
          onToggleManual: () =>
              setState(() => _guruInstManual = !_guruInstManual),
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

/// A tap-to-open date picker that looks like every other field on this form.
///
/// Written by hand because Flutter has no date equivalent of TextFormField and
/// an InkWell + InputDecorator is the only way to get the label, the hairline
/// border and the error text to match the surrounding inputs.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.hint,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.initialDate,
    required this.onChanged,
    this.helper,
    this.errorText,
  });

  final String label;
  final String hint;
  final DateTime? value;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialDate;
  final String? helper;
  final String? errorText;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: label,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? hint : formatDate(value),
          style: TextStyle(
            color: value == null ? AppColors.inkFaint : AppColors.ink,
          ),
        ),
      ),
    );
  }
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
