import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth_intent.dart';
import '../../core/session.dart';
import '../../data/profile_repository.dart';
import '../../data/reference_repository.dart';
import '../../models/city.dart';
import '../../models/profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pickers.dart';

/// Asked once, right after the first sign-in.
///
/// The role question is not cosmetic: picking "purohit" writes a
/// `pandit_profiles` row, and the existence of that row is what the `jobs_read`
/// RLS policy tests. No row, no jobs feed.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();

  UserRole? _role;
  City? _city;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Someone who tapped "Register as a purohit" on the sign-in page should not
    // have to answer the role question again.
    _role = AuthIntent.take();
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_role == null) {
      setState(() => _error = 'Choose whether you are booking or offering.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(profileRepositoryProvider).completeOnboarding(
            fullName: _name.text,
            role: _role!,
            cityId: _city?.id,
            bio: _bio.text,
            experienceYears: int.tryParse(_years.text.trim()),
          );
      await ref.read(sessionProvider.notifier).refresh();
      if (!mounted) return;
      // Purohits go straight into registration — asking for the role and then
      // dropping them on a job feed they cannot use was the old dead end.
      // ('/' was also not a real route, so this used to render "Not found".)
      context.go(_role == UserRole.purohit ? '/register-purohit' : '/jobs');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up your account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Gap.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'I am here to…',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Gap.md),
                _RoleTile(
                  title: 'Book a purohit',
                  subtitle: 'Post your ceremony and receive quotes.',
                  icon: Icons.family_restroom,
                  selected: _role == UserRole.family,
                  onTap: () => setState(() => _role = UserRole.family),
                ),
                const SizedBox(height: Gap.md),
                _RoleTile(
                  title: 'Work as a purohit',
                  subtitle: 'Browse ceremonies near you and apply.',
                  icon: Icons.self_improvement,
                  selected: _role == UserRole.purohit,
                  onTap: () => setState(() => _role = UserRole.purohit),
                ),
                const SizedBox(height: Gap.xxl),
                const Text(
                  'Full name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Gap.sm),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'e.g. Ramesh Sharma'),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Enter your name' : null,
                ),
                const SizedBox(height: Gap.lg),
                cities.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const Text(
                    'Could not load cities. You can add this later.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
                  ),
                  data: (list) => PickerField<City>(
                    label: 'City',
                    hint: 'Select your city',
                    value: _city,
                    items: list,
                    labelOf: (c) => c.label,
                    onChanged: (c) => setState(() => _city = c),
                  ),
                ),
                if (_role == UserRole.purohit) ...[
                  const SizedBox(height: Gap.lg),
                  const Text(
                    'Years of experience',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Gap.sm),
                  TextFormField(
                    controller: _years,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 12'),
                  ),
                  const SizedBox(height: Gap.lg),
                  const Text(
                    'About you',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Gap.sm),
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Gurukul, sampradaya, ceremonies you perform…',
                    ),
                  ),
                  const SizedBox(height: Gap.md),
                  const Text(
                    'Your listing stays unverified until an admin reviews your '
                    'Gurukul certificate or guru reference. You can still browse '
                    'in the meantime.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkFaint,
                      height: 1.4,
                    ),
                  ),
                ],
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
                      : const Text('Continue'),
                ),
                const SizedBox(height: Gap.lg),
                Center(
                  child: TextButton(
                    onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.marigold.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.saffron : AppColors.hairline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.saffronDark : AppColors.inkMuted),
            const SizedBox(width: Gap.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.saffron, size: 20),
          ],
        ),
      ),
    );
  }
}
